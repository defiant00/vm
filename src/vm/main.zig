const std = @import("std");
const VM = @import("vm.zig").VM;

test {
    _ = @import("string_pool.zig");
}

const version = std.SemanticVersion{ .major = 0, .minor = 1, .patch = 0 };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len == 2) {
        if (std.ascii.eqlIgnoreCase(args[1], "help")) {
            printUsage();
        } else if (std.ascii.eqlIgnoreCase(args[1], "version")) {
            std.debug.print("{}\n", .{version});
        } else {
            try runFile(alloc, args[1]);
        }
    } else {
        printUsage();
        return error.InvalidCommand;
    }
}

fn runFile(alloc: std.mem.Allocator, path: []const u8) !void {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const data = try file.readToEndAlloc(alloc, std.math.maxInt(usize));
    defer alloc.free(data);

    var vm: VM = undefined;
    try vm.init(alloc);
    defer vm.deinit();

    try vm.run(data);
}

fn printUsage() void {
    std.debug.print(
        \\Usage: vm [command]
        \\
        \\Commands:
        \\  [file]      Run specified file
        \\
        \\  help        Print this help and exit
        \\  version     Print version and exit
        \\
    , .{});
}
