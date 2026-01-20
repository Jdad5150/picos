//! Represents a coordinate value split into whole and decimal parts.
//! Used for precise motor positioning without floating point arithmetic
pub const CoordinateValue = struct {
    /// The integer part of the coordinate (can be negative)
    whole_num: i32,

    /// Array storing individual decimal digits (always positive)
    decimals: [3]i32,

    /// Parses a floating point coordinate into whole and decimal components.
    /// Decimals are capped at array length to prevent overflow.
    pub fn parse_raw_coordinate(self: *CoordinateValue, raw: f32, count: usize) void {
        self.whole_num = @intFromFloat(@trunc(raw));

        var fraction = @abs(raw - @as(f32, @floatFromInt(self.whole_num)));

        const max_count = @min(count, self.decimals.len);
        var i: usize = 0;
        while (i < max_count) : (i += 1) {
            fraction *= 10.0;
            const digit: i32 = @intFromFloat(@trunc(fraction));
            fraction -= @as(f32, @floatFromInt(digit));
            self.decimals[i] = digit;
        }
    }
};

const std = @import("std");

test "parse 3.14" {
    var coord = CoordinateValue{ .whole_num = 0, .decimals = undefined };
    coord.parse_raw_coordinate(3.14, 2);

    try std.testing.expectEqual(@as(i32, 3), coord.whole_num);
    try std.testing.expectEqual(@as(i32, 1), coord.decimals[0]);
    try std.testing.expectEqual(@as(i32, 4), coord.decimals[1]);
}

test "parse 123.456" {
    var coord = CoordinateValue{ .whole_num = 0, .decimals = undefined };
    coord.parse_raw_coordinate(123.456, 3);

    try std.testing.expectEqual(@as(i32, 123), coord.whole_num);
    try std.testing.expectEqual(@as(i32, 4), coord.decimals[0]);
    try std.testing.expectEqual(@as(i32, 5), coord.decimals[1]);
    try std.testing.expectEqual(@as(i32, 6), coord.decimals[2]);
}

test "parse 123.45678" {
    var coord = CoordinateValue{ .whole_num = 0, .decimals = undefined };
    coord.parse_raw_coordinate(123.45678, 5);

    try std.testing.expectEqual(@as(i32, 123), coord.whole_num);
    try std.testing.expectEqual(@as(i32, 4), coord.decimals[0]);
    try std.testing.expectEqual(@as(i32, 5), coord.decimals[1]);
    try std.testing.expectEqual(@as(i32, 6), coord.decimals[2]);
}

test "parse -3.14" {
    var coord = CoordinateValue{ .whole_num = 0, .decimals = undefined };
    coord.parse_raw_coordinate(-3.14, 2);

    try std.testing.expectEqual(@as(i32, -3), coord.whole_num);
    try std.testing.expectEqual(@as(i32, 1), coord.decimals[0]);
    try std.testing.expectEqual(@as(i32, 4), coord.decimals[1]);
}
