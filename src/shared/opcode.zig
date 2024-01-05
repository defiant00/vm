pub const OpCode = enum {
    no,

    val_i8,
    val_i16,
    val_i32,
    val_i64,

    val_str,

    add,
    subtract,
    multiply,
    divide,
    remainder,
};
