//! Continuous-rotation servo controller for RP2040.
//!
//! Accepts commands over UART0 at 115200 baud to control an LED and
//! set servo speed via PWM on GPIO2.
//!
//! Supported commands (newline-terminated):
//!   - `on`     — turn LED on
//!   - `off`    — turn LED off
//!   - `toggle` — toggle LED state
//!   - `<float>` — set servo speed (0–100, where 50 is stopped)

const std = @import("std");
const microzig = @import("microzig");
const rp2xxx = microzig.hal;
const time = rp2xxx.time;
const uart = rp2xxx.uart;

const pin_config = rp2xxx.pins.GlobalConfiguration{
    .GPIO25 = .{ .name = "led", .direction = .out },
    .GPIO0 = .{ .name = "uart_tx", .function = .UART0_TX },
    .GPIO1 = .{ .name = "uart_rx", .function = .UART0_RX },
    .GPIO2 = .{ .name = "servo", .function = .PWM1_A },
};

pub fn main() !void {
    const pins = pin_config.apply();

    var uart0 = uart.instance.num(0);
    uart0.apply(.{
        .baud_rate = 115200,
        .clock_config = rp2xxx.clock_config,
    });

    pins.servo.slice().set_clk_div(64, 0);
    pins.servo.slice().set_wrap(39062);
    pins.servo.slice().enable();

    var buf: [32]u8 = undefined;
    var idx: usize = 0;

    while (true) {
        if (uart0.read_word() catch null) |byte| {
            if (byte == '\n' or byte == '\r') {
                if (idx > 0) {
                    handle_command(buf[0..idx], &pins);
                    idx = 0;
                }
            } else if (idx < buf.len) {
                buf[idx] = byte;
                idx += 1;
            }
        }
        time.sleep_us(100);
    }
}

/// Dispatches a UART command. LED commands are matched by name;
/// anything else is parsed as a float speed value for the servo.
fn handle_command(cmd: []const u8, pins: anytype) void {
    if (std.mem.eql(u8, cmd, "on")) {
        pins.led.put(1);
    } else if (std.mem.eql(u8, cmd, "off")) {
        pins.led.put(0);
    } else if (std.mem.eql(u8, cmd, "toggle")) {
        pins.led.toggle();
    } else {
        const speed = std.fmt.parseFloat(f32, cmd) catch return;
        set_servo_speed(speed, pins);
    }
}

/// Per-servo calibration offset applied to the center point (dead stop).
/// Adjust if the servo doesn't stop cleanly at speed 50.
const servo_trim_offset: f32 = 0.0;

/// Sets the continuous-rotation servo speed by writing a PWM duty level.
/// `speed` is expected in the range 0–100, where 50 is the center (stopped)
/// point. Values below 50 spin one direction, above 50 the other.
/// The pulse width is linearly interpolated between 1 ms and 2 ms
/// (1953–3906 timer counts at the configured clock divider and wrap).
fn set_servo_speed(speed: f32, pins: anytype) void {
    const min_pulse: f32 = 1953.0;
    const max_pulse: f32 = 3906.0;

    const pulse = min_pulse + (speed / 100.0) * (max_pulse - min_pulse) + servo_trim_offset;
    pins.servo.set_level(@as(u16, @intFromFloat(pulse)));
}

/// Sets a standard (positional) servo to a given position.
/// `position` is expected in the range 0–100, mapping linearly to the
/// full pulse range (1 ms – 2 ms).
fn set_servo_position(position: f32, pins: anytype) void {
    const min_pulse: f32 = 1953.0;
    const max_pulse: f32 = 3906.0;

    const pulse = min_pulse + (position / 100.0) * (max_pulse - min_pulse) + servo_trim_offset;
    pins.servo.set_level(@as(u16, @intFromFloat(pulse)));
}
