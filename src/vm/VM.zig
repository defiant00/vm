const std = @import("std");
const Allocator = std.mem.Allocator;
const GcAllocator = @import("GcAllocator.zig");

const VM = @This();

parent_allocator: Allocator,
gc: GcAllocator,
allocator: Allocator,

code: []const u8,
strings: std.StringArrayHashMap(void),

pub fn init(self: *VM, alloc: Allocator) !void {
    self.parent_allocator = alloc;
    self.gc = GcAllocator.init(self);
    self.allocator = self.gc.allocator();

    self.code = "";
    self.strings = std.StringArrayHashMap(void).init(alloc);
}

pub fn deinit(self: *VM) void {
    _ = self;
}

pub fn collectGarbage(self: *VM) void {
    _ = self;
}

pub fn load(self: *VM, data: []const u8) !void {
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
        if (data[pos] != '#') {
            return error.MissingMarker;
        }
        pos += 1;
        const header = data[pos .. pos + 4];
        pos += 4;
        const size = std.mem.readVarInt(u32, data[pos .. pos + 4], .little);
        pos += 4;
        const block_data = data[pos .. pos + size];
        pos += size;

        if (std.mem.eql(u8, header, "code")) {
            self.code = block_data;
        } else if (std.mem.eql(u8, header, "str\x00")) {
            //
        } else {
            std.debug.print("Error: Unknown block type '{s}'\n", .{header});
        }
    }
}
