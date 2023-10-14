const std = @import("std");
const Allocator = std.mem.Allocator;
const spec = @import("shared").spec;

pub const Assembly = struct {
    major_version: u32,
    minor_version: u32,
    patch_version: u32,
    build_version: u32,

    pub fn init(self: *Assembly, alloc: Allocator, source: []const u8) !void {
        _ = alloc;
        _ = source;

        self.major_version = 1;
        self.minor_version = 0;
        self.patch_version = 0;
        self.build_version = 0;
    }

    pub fn deinit(self: *Assembly) void {
        _ = self;
    }

    pub fn write(self: *Assembly, writer: anytype) !void {
        // offset:size

        // magic number signature 0:4
        try writer.writeAll(&[_]u8{ 0x64, 0x65, 0x66, 0x30 });

        // spec major version 4:2
        try writer.writeIntLittle(u16, spec.version.major);

        // spec minor version 6:2
        try writer.writeIntLittle(u16, spec.version.minor);

        // assembly major version 8:4
        try writer.writeIntLittle(u32, self.major_version);

        // assembly minor version 12:4
        try writer.writeIntLittle(u32, self.minor_version);

        // assembly patch version 16:4
        try writer.writeIntLittle(u32, self.patch_version);

        // assembly build version 20:4
        try writer.writeIntLittle(u32, self.build_version);

        // string heap offset 24:4
        try writer.writeIntLittle(u32, 32);

        // code heap offset 28:4
        try writer.writeIntLittle(u32, 0);
    }
};
