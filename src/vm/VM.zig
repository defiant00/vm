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

    // header
    if (!std.mem.eql(u8, data[0..4], "def0")) {
        return error.InvalidSignature;
    }

    std.debug.print("Spec {d}.{d}\nAsm {d}.{d}.{d}.{d}\n", .{
        std.mem.readInt(u16, data[4..6], .little),
        std.mem.readInt(u16, data[6..8], .little),
        std.mem.readInt(u32, data[8..12], .little),
        std.mem.readInt(u32, data[12..16], .little),
        std.mem.readInt(u32, data[16..20], .little),
        std.mem.readInt(u32, data[20..24], .little),
    });

    // data blocks
    var pos: usize = 24;
    while (pos < data.len) {
        std.debug.print("header '{s}'\n", .{data[pos .. pos + 8]});
        pos += 8;
        const size = std.mem.readVarInt(u32, data[pos .. pos + 4], .little);
        pos += 4;
        std.debug.print("  size {d}\n", .{size});
        pos += size;
    }
}
