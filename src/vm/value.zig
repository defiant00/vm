const std = @import("std");

const quiet_nan: u64 = 0b01111111_11111100_00000000_00000000_00000000_00000000_00000000_00000000;
const sign_bit: u64 = 0b10000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000;
const object_tag = sign_bit | quiet_nan;
const empty_val = quiet_nan;
const nil_val = quiet_nan | 1;
const true_val = quiet_nan | 2;
const false_val = quiet_nan | 3;

pub const Value = u64;

// initializers

pub fn boolean(val: bool) Value {
    return if (val) true_val else false_val;
}

pub fn empty() Value {
    return empty_val;
}

pub fn nil() Value {
    return nil_val;
}

pub fn number(val: f64) Value {
    return @as(*const u64, @ptrCast(&val)).*;
}

// checks

pub fn isBool(val: Value) bool {
    return val == true_val or val == false_val;
}

pub fn isEmpty(val: Value) bool {
    return val == empty_val;
}

pub fn isNil(val: Value) bool {
    return val == nil_val;
}

pub fn isNumber(val: Value) bool {
    return (val & quiet_nan) != quiet_nan;
}

// casts

pub fn asBool(val: Value) bool {
    return val == true_val;
}

pub fn asNumber(val: Value) f64 {
    return @bitCast(val);
    // return @as(*const f64, @ptrCast(&val)).*;
}

pub fn isFalsey(val: Value) bool {
    return val == nil_val or val == false_val;
}

pub fn print(val: Value) void {
    if (isBool(val)) {
        if (asBool(val)) {
            std.debug.print("true", .{});
        } else {
            std.debug.print("false", .{});
        }
    } else if (isNil(val)) {
        std.debug.print("nil", .{});
    } else if (isNumber(val)) {
        std.debug.print("{d}", .{asNumber(val)});
    } else {
        std.debug.print("empty", .{});
    }
}
