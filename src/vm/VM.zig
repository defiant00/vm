const std = @import("std");
const Allocator = std.mem.Allocator;
const GcAllocator = @import("GcAllocator.zig");

const VM = @This();

parent_allocator: Allocator,
gc: GcAllocator,
allocator: Allocator,

pub fn init(self: *VM, allocator: Allocator) !void {
    self.parent_allocator = allocator;
    self.gc = GcAllocator.init(self);
    self.allocator = self.gc.allocator();
}

pub fn deinit(self: *VM) void {
    _ = self;
}

pub fn collectGarbage(self: *VM) void {
    _ = self;
}

pub fn run(self: *VM, data: []const u8) !void {
    _ = self;

    var data_buf = std.io.fixedBufferStream(data);
    const data_reader = data_buf.reader();

    // header
    if (!std.mem.eql(u8, &try data_reader.readBytesNoEof(4), &[_]u8{ 0x64, 0x65, 0x66, 0x30 })) {
        return error.InvalidSignature;
    }

    std.debug.print("Spec {d}.{d}\nAsm {d}.{d}.{d}.{d}\n", .{
        try data_reader.readInt(u16, .little),
        try data_reader.readInt(u16, .little),
        try data_reader.readInt(u32, .little),
        try data_reader.readInt(u32, .little),
        try data_reader.readInt(u32, .little),
        try data_reader.readInt(u32, .little),
    });
}
