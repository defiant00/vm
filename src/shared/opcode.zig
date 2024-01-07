pub const OpCode = enum {
    no,

    push_i8,
    push_i16,
    push_i32,

    push_str,

    add,
    subtract,
    multiply,
    divide,
    remainder,

    return_,
};
