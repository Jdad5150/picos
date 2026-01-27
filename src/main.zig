const std = @import("std");
const microzig = @import("microzig");
const rp2xxx = microzig.hal;
const time = rp2xxx.time;
const uart = rp2xxx.uart;
const CoordinateValue = @import("CoordinateValue.zig");

// For LED TESTING only
const LONG_BLINK_MS = 500;
const SHORT_BLINK_MS = 200;
const BETWEEN_DIGITS_MS = 300;
const BETWEEN_PARTS_MS = 700;

const pin_config = rp2xxx.pins.GlobalConfiguration{
    .GPIO25 = .{ .name = "led", .direction = .out }, // LED to blink
    .GPIO0 = .{ .name = "uart_tx", .function = .UART0_TX }, // Transmitter pin
    .GPIO1 = .{ .name = "uart_rx", .function = .UART0_RX }, // Receiver pin
};

pub fn main() !void {
    const pins = pin_config.apply(); // Apply pin configuration

    var uart0 = uart.instance.num(0); // Get UART0 instance
    uart0.apply(.{
        .baud_rate = 115200, // Baud rate - must match on both sender and receiver
        .clock_config = rp2xxx.clock_config,
    });

    var buf: [32]u8 = undefined; // Create command buffer
    var idx: usize = 0;

    while (true) {
        if (uart0.read_word() catch null) |byte| { // Read one byte if available

            if (byte == '\n' or byte == '\r') { // Check if end of command
                if (idx > 0) {
                    handle_command(buf[0..idx], &pins);
                    idx = 0;
                }
            } else if (idx < buf.len) {
                buf[idx] = byte;
                idx += 1;
            }
        }
        time.sleep_us(100); // Small delay to avoid busy-waiting
    }
}

fn handle_command(cmd: []const u8, pins: anytype) void {
    if (std.mem.eql(u8, cmd, "on")) {
        pins.led.put(1);
    } else if (std.mem.eql(u8, cmd, "off")) {
        pins.led.put(0);
    } else if (std.mem.eql(u8, cmd, "toggle")) {
        pins.led.toggle();
    } else {
        const value = std.fmt.parseFloat(f32, cmd) catch return;
        var coord = CoordinateValue.CoordinateValue{ .whole_num = 0, .decimals = undefined };
        coord.parse_raw_coordinate(value, 3);
        visualize_coordinate(coord, pins);
    }
}

fn visualize_coordinate(coord: CoordinateValue.CoordinateValue, pins: anytype) void {
    // Blink whole number with long blinks
    var i: usize = 0;
    while (i < @abs(coord.whole_num)) : (i += 1) {
        pins.led.put(1);
        time.sleep_ms(LONG_BLINK_MS);
        pins.led.put(0);
        time.sleep_ms(BETWEEN_DIGITS_MS);
    }

    time.sleep_ms(BETWEEN_PARTS_MS);

    // Blink decimals with short blinks
    for (coord.decimals) |digit| {
        var j: usize = 0;
        while (j < @abs(digit)) : (j += 1) {
            pins.led.put(1);
            time.sleep_ms(SHORT_BLINK_MS);
            pins.led.put(0);
            time.sleep_ms(BETWEEN_DIGITS_MS);
        }
        time.sleep_ms(BETWEEN_PARTS_MS);
    }
}
