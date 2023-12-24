const std = @import("std");
const Allocator = std.mem.Allocator;
const spec = @import("shared").spec;

const Assembly = @This();

alloc: Allocator,

major_version: u32,
minor_version: u32,
patch_version: u32,
build_version: u32,

pub fn init(alloc: Allocator) Assembly {
    return .{
        .alloc = alloc,

        .major_version = 1,
        .minor_version = 0,
        .patch_version = 0,
        .build_version = 0,
    };
}

pub fn deinit(self: Assembly) void {
    _ = self;
}

pub fn assemble(self: *Assembly, source: []const u8) !void {
    _ = self;
    _ = source;
}

pub fn write(self: Assembly, writer: anytype) !void {
    // offset:size

    // magic number signature 0:4
    try writer.writeAll(&[_]u8{ 0x64, 0x65, 0x66, 0x30 });

    // spec major version 4:2
    try writer.writeInt(u16, spec.version.major, .little);

    // spec minor version 6:2
    try writer.writeInt(u16, spec.version.minor, .little);

    // assembly major version 8:4
    try writer.writeInt(u32, self.major_version, .little);

    // assembly minor version 12:4
    try writer.writeInt(u32, self.minor_version, .little);

    // assembly patch version 16:4
    try writer.writeInt(u32, self.patch_version, .little);

    // assembly build version 20:4
    try writer.writeInt(u32, self.build_version, .little);

    // string heap offset 24:4
    try writer.writeInt(u32, 32, .little);

    // code heap offset 28:4
    try writer.writeInt(u32, 0, .little);
}
