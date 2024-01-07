const std = @import("std");
const Allocator = std.mem.Allocator;
const Assembly = @import("Assembly.zig");
const flags = @import("flags.zig");
const GcAllocator = @import("GcAllocator.zig");
const OpCode = @import("shared").OpCode;
const value = @import("value.zig");
const Value = value.Value;

const VM = @This();

parent_allocator: Allocator,
gc: GcAllocator,
allocator: Allocator,
assembly: Assembly,

stack: [1024]Value,
stack_top: [*]Value,

pub fn init(self: *VM, alloc: Allocator) !void {
    self.parent_allocator = alloc;
    self.gc = GcAllocator.init(self);
    self.allocator = self.gc.allocator();
    self.assembly = Assembly.init(self.allocator);

    self.resetStack();
}

pub fn deinit(self: VM) void {
    self.assembly.deinit();
}

pub fn collectGarbage(self: *VM) void {
    _ = self;
}

pub fn call(self: *VM, name: []const u8) !void {
    _ = name;
    // TODO look up and call the function

    var ip: [*]const u8 = self.assembly.code.ptr;
    var running = true;
    while (running) {
        if (flags.trace_execution) {
            std.debug.print("  ", .{});
            var slot: [*]Value = &self.stack;
            while (@intFromPtr(slot) < @intFromPtr(self.stack_top)) : (slot += 1) {
                std.debug.print("[ ", .{});
                value.print(slot[0]);
                std.debug.print(" ]", .{});
            }
            std.debug.print("\n", .{});
            // TODO print instruction disassembly
        }

        const instruction = ip[0];
        ip += 1;
        const op: OpCode = @enumFromInt(instruction);
        switch (op) {
            .no => {},

            .push_i8 => {
                const val = readInt(&ip, i8);
                self.push(value.number(@floatFromInt(val)));
            },
            .push_i16 => {
                const val = readInt(&ip, i16);
                self.push(value.number(@floatFromInt(val)));
            },
            .push_i32 => {
                const val = readInt(&ip, i32);
                self.push(value.number(@floatFromInt(val)));
            },

            .push_str => ip += 1,

            .add => {},
            .subtract => {},
            .multiply => {},
            .divide => {},
            .remainder => {},

            .return_ => running = false,
        }
    }
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
            var strs = std.ArrayList([]const u8).init(self.allocator);
            var str_pos: usize = 0;
            while (str_pos < block_data.len) {
                const str_len = block_data[str_pos];
                str_pos += 1;
                try strs.append(block_data[str_pos .. str_pos + str_len]);
                str_pos += str_len;
            }
            self.assembly.strings = try strs.toOwnedSlice();
        } else {
            std.debug.print("Error: Unknown block type '{s}'\n", .{header});
        }
    }

    if (flags.print_code) self.assembly.printDisassembly();
}

// code helpers

fn readInt(ip: *[*]const u8, comptime T: type) T {
    const size = @divExact(@typeInfo(T).Int.bits, 8);
    const val = std.mem.readInt(T, ip.*[0..size], .little);
    ip.* += size;
    return val;
}

// stack helpers

fn pop(self: *VM) Value {
    self.stack_top -= 1;
    return self.stack_top[0];
}

fn push(self: *VM, val: Value) void {
    self.stack_top[0] = val;
    self.stack_top += 1;
}

fn resetStack(self: *VM) void {
    self.stack_top = &self.stack;
}
