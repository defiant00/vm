const std = @import("std");

const version = std.SemanticVersion{ .major = 0, .minor = 0, .patch = 1 };

pub fn main() !void {
    std.debug.print("asm\n", .{});
}
