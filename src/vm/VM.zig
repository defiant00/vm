const std = @import("std");
const Allocator = std.mem.Allocator;
const Assembly = @import("Assembly.zig");
const flags = @import("flags.zig");
const GcAllocator = @import("GcAllocator.zig");

const VM = @This();

parent_allocator: Allocator,
gc: GcAllocator,
allocator: Allocator,
assembly: Assembly,

pub fn init(self: *VM, alloc: Allocator) !void {
    self.parent_allocator = alloc;
    self.gc = GcAllocator.init(self);
    self.allocator = self.gc.allocator();
    self.assembly = Assembly.init();
}

pub fn deinit(self: VM) void {
    self.assembly.deinit();
}

pub fn collectGarbage(self: *VM) void {
    _ = self;
}

pub fn load(self: *VM, data: []const u8) !void {
    // header
    if (!std.mem.eql(u8, data[0..4], "def0")) {
        return error.InvalidSignature;
    }

    self.assembly.major_version = std.mem.readInt(u32, data[8..12], .little);
    self.assembly.minor_version = std.mem.readInt(u32, data[12..16], .little);
    self.assembly.patch_version = std.mem.readInt(u32, data[16..20], .little);
    self.assembly.build_version = std.mem.readInt(u32, data[20..24], .little);

    // data blocks
    var pos: usize = 24;
    while (pos < data.len) {
        if (data[pos] != '#') {
            return error.MissingMarker;
        }
        pos += 1;
        const header = data[pos .. pos + 4];
        pos += 4;
        const size = std.mem.readInt(u32, data[pos..][0..4], .little);
        pos += 4;
        const block_data = data[pos .. pos + size];
        pos += size;

        if (std.mem.eql(u8, header, "code")) {
            self.assembly.code = block_data;
        } else if (std.mem.eql(u8, header, "str\x00")) {
            // TODO strings
        } else {
            std.debug.print("Error: Unknown block type '{s}'\n", .{header});
        }
    }

    if (flags.print_code) self.assembly.printDisassembly();
}
