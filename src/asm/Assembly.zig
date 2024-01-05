const std = @import("std");
const Allocator = std.mem.Allocator;
const flags = @import("flags.zig");
const Lexer = @import("lexer.zig").Lexer;
const OpCode = @import("shared").OpCode;
const spec = @import("shared").spec;
const Token = @import("lexer.zig").Token;
const TokenType = @import("lexer.zig").TokenType;

const Assembly = @This();

const Parser = struct {
    current: Token,
    prior: Token,
};

major_version: u32,
minor_version: u32,
patch_version: u32,
build_version: u32,

code: std.ArrayList(u8),
strings: std.StringArrayHashMap(void),

lexer: Lexer,
parser: Parser,

pub fn init(alloc: Allocator) Assembly {
    return .{
        .major_version = 1,
        .minor_version = 0,
        .patch_version = 0,
        .build_version = 0,

        .code = std.ArrayList(u8).init(alloc),
        .strings = std.StringArrayHashMap(void).init(alloc),

        .lexer = undefined,
        .parser = undefined,
    };
}

pub fn deinit(self: *Assembly) void {
    self.code.deinit();
    self.strings.deinit();
}

pub fn assemble(self: *Assembly, source: []const u8) !void {
    self.lexer = Lexer.init(source);

    self.advance();
    while (!self.match(.eof)) {
        try self.command();
    }
}

pub fn write(self: Assembly, writer: anytype) !void {
    // offset:size

    // magic number signature 0:4
    try writer.writeAll("def0");

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

    // string block
    if (self.strings.count() > 0) {
        // #str
        try writer.writeAll("#str\x00");

        // TODO sizes greater than a single byte

        var size: usize = 0;
        for (self.strings.keys()) |str| {
            size += str.len + 1;
        }
        try writer.writeInt(u32, @intCast(size), .little);

        for (self.strings.keys()) |str| {
            try writer.writeByte(@intCast(str.len));
            try writer.writeAll(str);
        }
    }

    // code block
    if (self.code.items.len > 0) {
        // #code
        try writer.writeAll("#code");
        // size
        try writer.writeInt(u32, @intCast(self.code.items.len), .little);
        // code
        try writer.writeAll(self.code.items);
    }
}

// parser helpers

fn advance(self: *Assembly) void {
    self.parser.prior = self.parser.current;

    while (true) {
        self.parser.current = self.lexer.lexToken();
        if (flags.print_tokens) {
            std.debug.print("{} '{s}'\n", .{ self.parser.current.type, self.parser.current.value });
        }
        if (self.parser.current.type != .error_) break;

        self.errorAt(self.parser.current, self.parser.current.value);
    }
}

fn check(self: Assembly, expected: TokenType) bool {
    return self.parser.current.type == expected;
}

fn consume(self: *Assembly, expected: TokenType, message: []const u8) void {
    if (self.parser.current.type == expected) {
        self.advance();
    } else {
        self.errorAt(self.parser.current, message);
    }
}

fn emitOp(self: *Assembly, op: OpCode) !void {
    try self.code.append(@intFromEnum(op));
}

fn errorAt(self: Assembly, token: Token, message: []const u8) void {
    // TODO panic and error parser modes
    _ = self;

    if (token.type == .eof) {
        std.debug.print("[{}:{}-{}:{}] Error at end: {s}\n", .{
            token.start_line,
            token.start_column,
            token.end_line,
            token.end_column,
            message,
        });
    } else if (token.type != .error_) {
        std.debug.print("[{}:{}-{}:{}] Error at '{s}': {s}\n", .{
            token.start_line,
            token.start_column,
            token.end_line,
            token.end_column,
            token.value,
            message,
        });
    } else {
        std.debug.print("[{}:{}-{}:{}] Error: {s}\n", .{
            token.start_line,
            token.start_column,
            token.end_line,
            token.end_column,
            message,
        });
    }
}

fn getAddString(self: *Assembly, str: []const u8) !usize {
    return (try self.strings.getOrPut(str)).index;
}

fn match(self: *Assembly, expected: TokenType) bool {
    if (!self.check(expected)) return false;
    self.advance();
    return true;
}

// parser core

fn command(self: *Assembly) !void {
    if (self.match(.literal)) {
        try self.literal();
    } else if (self.match(.string)) {
        try self.string();
    } else {
        // TODO error
        self.advance();
    }
}

fn literal(self: *Assembly) !void {
    if (std.mem.startsWith(u8, self.parser.prior.value, "op.")) {
        try self.opCode();
    } else {
        try self.number();
    }
}

fn number(self: *Assembly) !void {
    // TODO binary, octal, decimal, hex with separators and int/float detection

    const val = try std.fmt.parseInt(i64, self.parser.prior.value, 10);

    if (val > std.math.maxInt(i32) or val < std.math.minInt(i32)) {
        try self.emitOp(.val_i64);
        try self.code.writer().writeInt(i64, val, .little);
    } else if (val > std.math.maxInt(i16) or val < std.math.minInt(i16)) {
        try self.emitOp(.val_i32);
        try self.code.writer().writeInt(i32, @intCast(val), .little);
    } else if (val > std.math.maxInt(i8) or val < std.math.minInt(i8)) {
        try self.emitOp(.val_i16);
        try self.code.writer().writeInt(i16, @intCast(val), .little);
    } else {
        try self.emitOp(.val_i8);
        try self.code.writer().writeInt(i8, @intCast(val), .little);
    }
}

fn opCode(self: *Assembly) !void {
    const op = self.parser.prior.value[3..];
    if (std.mem.eql(u8, op, "add")) {
        try self.emitOp(.add);
    } else if (std.mem.eql(u8, op, "divide")) {
        try self.emitOp(.divide);
    } else if (std.mem.eql(u8, op, "multiply")) {
        try self.emitOp(.multiply);
    } else if (std.mem.eql(u8, op, "no")) {
        try self.emitOp(.no);
    } else if (std.mem.eql(u8, op, "remainder")) {
        try self.emitOp(.remainder);
    } else if (std.mem.eql(u8, op, "subtract")) {
        try self.emitOp(.subtract);
    } else if (std.mem.eql(u8, op, "version")) {
        self.opVersion();
    } else {
        self.errorAt(self.parser.prior, "unknown opcode");
    }
}

fn opVersion(self: *Assembly) void {
    self.consume(.literal, "missing version value");

    // TODO parse version numbers
    // TODO support _ separator

    var prior_digit = false;
    var decimal_count: u8 = 0;
    for (self.parser.prior.value) |c| {
        switch (c) {
            '.' => {
                if (!prior_digit) {
                    self.errorAt(self.parser.prior, "decimal must follow a digit");
                    return;
                }

                prior_digit = false;
                decimal_count += 1;

                if (decimal_count > 3) {
                    self.errorAt(self.parser.prior, "too many values for version");
                    return;
                }
            },
            '0'...'9' => prior_digit = true,
            else => {
                self.errorAt(self.parser.prior, "invalid character in version");
                return;
            },
        }
    }
}

fn string(self: *Assembly) !void {
    const idx = try self.getAddString(self.parser.prior.value);
    try self.emitOp(.val_str);
    try self.code.append(@intCast(idx));
}
