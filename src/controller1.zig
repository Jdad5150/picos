//! Stepper motor controller for RP2040.
//!
//! Accepts commands over UART0 at 115200 baud to control an LED and
//! drive a stepper motor to absolute positions via step/direction pins.
//!
//! Supported commands (newline-terminated):
//!   - `on`     — turn LED on
//!   - `off`    — turn LED off
//!   - `toggle` — toggle LED state
//!   - `<float>` — move stepper to the given absolute step position

const std = @import("std");
const microzig = @import("microzig");
const rp2xxx = microzig.hal;
const time = rp2xxx.time;
const uart = rp2xxx.uart;

const pin_config = rp2xxx.pins.GlobalConfiguration{
    .GPIO25 = .{ .name = "led", .direction = .out },
    .GPIO0 = .{ .name = "uart_tx", .function = .UART0_TX },
    .GPIO1 = .{ .name = "uart_rx", .function = .UART0_RX },
    .GPIO2 = .{ .name = "step_pin", .function = .SIO, .direction = .out },
    .GPIO3 = .{ .name = "dir_pin", .function = .SIO, .direction = .out },
};

const step_delay_us: u64 = 1000;

pub fn main() !void {
    const pins = pin_config.apply();
    var current_position: i32 = 0;

    //const upper_bound = // TODO Figure out the actual bounds during testing ;
    //const lower_bound = // TODO Figure out the actual bounds during testing ;

    var uart0 = uart.instance.num(0);
    uart0.apply(.{
        .baud_rate = 115200,
        .clock_config = rp2xxx.clock_config,
    });

    var buf: [32]u8 = undefined;
    var idx: usize = 0;

    while (true) {
        if (uart0.read_word() catch null) |byte| {
            if (byte == '\n' or byte == '\r') {
                if (idx > 0) {
                    handle_command(buf[0..idx], &pins, &current_position);
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
/// anything else is parsed as a float target position for the stepper.
fn handle_command(cmd: []const u8, pins: anytype, current_position: *i32) void {
    if (std.mem.eql(u8, cmd, "on")) {
        pins.led.put(1);
    } else if (std.mem.eql(u8, cmd, "off")) {
        pins.led.put(0);
    } else if (std.mem.eql(u8, cmd, "toggle")) {
        pins.led.toggle();
    } else {
        const target = std.fmt.parseFloat(f32, cmd) catch return;
        //const target_clamped = std.math.clamp(target_raw, lower_bound, upper_bound); // TODO Figure out the actual bounds during testing
        const delta = @as(i32, @intFromFloat(target)) - current_position.*;

        moveSteps(delta, pins);
        current_position.* = @intFromFloat(target);
    }
}

/// Moves the stepper motor by `steps` steps. Positive values move in one
/// direction, negative in the other. Each step pulses the step pin high
/// for 2 us with a 1000 us period between steps.
fn moveSteps(steps: i32, pins: anytype) void {
    if (steps > 0) {
        pins.dir_pin.put(1);
    } else {
        pins.dir_pin.put(0);
    }

    const abs_steps = @abs(steps);

    var i: u32 = 0;
    while (i < abs_steps) : (i += 1) {
        pins.step_pin.put(1);
        time.sleep_us(2);
        pins.step_pin.put(0);
        time.sleep_us(step_delay_us);
    }
}
