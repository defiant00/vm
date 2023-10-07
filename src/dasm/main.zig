const std = @import("std");

const version = std.SemanticVersion{ .major = 0, .minor = 1, .patch = 0 };

pub fn main() !void {
    std.debug.print("dasm\n", .{});
}
