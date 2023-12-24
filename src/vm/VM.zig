const std = @import("std");
const Allocator = std.mem.Allocator;
const GcAllocator = @import("gc_allocator.zig").GcAllocater;

pub const VM = struct {
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
        _ = data;
    }
};
