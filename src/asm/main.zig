const std = @import("std");
const spec = @import("shared").spec;

const version = std.SemanticVersion{ .major = 0, .minor = 1, .patch = 0 };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len == 2) {
        if (std.mem.eql(u8, args[1], "help")) {
            printUsage();
        } else if (std.mem.eql(u8, args[1], "version")) {
            std.debug.print("{}\n", .{version});
        } else {
            try assembleFile(alloc, args[1]);
        }
    } else {
        printUsage();
        return error.InvalidCommand;
    }
}

fn assembleFile(alloc: std.mem.Allocator, path: []const u8) !void {
    var in_file = try std.fs.cwd().openFile(path, .{});
    defer in_file.close();

    const source = try in_file.readToEndAlloc(alloc, std.math.maxInt(usize));
    defer alloc.free(source);

    const strs = [_][]const u8{ path, ".vmex" };
    const out_path = try std.mem.concat(alloc, u8, &strs);
    defer alloc.free(out_path);

    const out_file = try std.fs.cwd().createFile(out_path, .{});
    defer out_file.close();

    var buffered_writer = std.io.bufferedWriter(out_file.writer());
    const writer = buffered_writer.writer();

    // magic number signature
    try writer.writeAll(&[_]u8{ 0x64, 0x65, 0x66, 0x30 });

    // spec major version
    try writer.writeIntLittle(u16, spec.version.major);

    // spec minor version
    try writer.writeIntLittle(u16, spec.version.minor);

    // assembly major version
    try writer.writeIntLittle(u32, 1);

    // assembly minor version
    try writer.writeIntLittle(u32, 0);

    // assembly patch version
    try writer.writeIntLittle(u32, 0);

    // assembly build version
    try writer.writeIntLittle(u32, 0);

    try buffered_writer.flush();
}

fn printUsage() void {
    std.debug.print(
        \\Usage: asm [command]
        \\
        \\Commands:
        \\  [file]      Assemble specified file
        \\
        \\  help        Print this help and exit
        \\  version     Print version and exit
        \\
    , .{});
}
