const std = @import("std");
const Allocator = std.mem.Allocator;
const OpCode = @import("shared").OpCode;

const Assembly = @This();

allocator: Allocator,

major_version: u32,
minor_version: u32,
patch_version: u32,
build_version: u32,

code: []const u8,
strings: [][]const u8,

pub fn init(alloc: Allocator) Assembly {
    return .{
        .allocator = alloc,

        .major_version = 1,
        .minor_version = 0,
        .patch_version = 0,
        .build_version = 0,

        .code = undefined,
        .strings = undefined,
    };
}

pub fn deinit(self: Assembly) void {
    self.allocator.free(self.strings);
}

pub fn printDisassembly(self: Assembly) void {
    std.debug.print("== [name?] ==\n", .{});

    var offset: usize = 0;
    while (offset < self.code.len) {
        offset = self.printDisassemblyInstruction(offset);
    }
}

fn printDisassemblyInstruction(self: Assembly, offset: usize) usize {
    std.debug.print("{d:0>4} ", .{offset});

    const op: OpCode = @enumFromInt(self.code[offset]);
    return switch (op) {
        .no => printSimpleInstruction("no", offset),

        .push_i8 => self.printIntInstruction(i8, "push i8", offset),
        .push_i16 => self.printIntInstruction(i16, "push i16", offset),
        .push_i32 => self.printIntInstruction(i32, "push i32", offset),

        .push_str => self.printStringInstruction(u8, "push string", offset),

        .add => printSimpleInstruction("add", offset),
        .subtract => printSimpleInstruction("subtract", offset),
        .multiply => printSimpleInstruction("multiply", offset),
        .divide => printSimpleInstruction("divide", offset),
        .remainder => printSimpleInstruction("remainder", offset),

        .return_ => printSimpleInstruction("return", offset),
    };
}

fn printIntInstruction(self: Assembly, comptime T: type, name: []const u8, offset: usize) usize {
    const size = @divExact(@typeInfo(T).Int.bits, 8);
    const val = std.mem.readInt(T, self.code[offset + 1 ..][0..size], .little);
    std.debug.print("{s: <16} {d}\n", .{ name, val });
    return offset + size + 1;
}

fn printStringInstruction(self: Assembly, comptime T: type, name: []const u8, offset: usize) usize {
    const size = @divExact(@typeInfo(T).Int.bits, 8);
    const idx = std.mem.readInt(T, self.code[offset + 1 ..][0..size], .little);
    std.debug.print("{s: <16} \"{s}\"\n", .{ name, self.strings[idx] });
    return offset + size + 1;
}

fn printSimpleInstruction(name: []const u8, offset: usize) usize {
    std.debug.print("{s}\n", .{name});
    return offset + 1;
}
