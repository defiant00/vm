pub const Token = struct {
    type: Type,
    value: []const u8,
    line: usize,
    column: usize,

    pub const Type = enum {
        left_paren,
        right_paren,
        literal,
        string,
        error_,
        eof,
    };
};

pub const Lexer = struct {
    source: []const u8,
    line: usize,
    column: usize,
    start_index: usize,
    current_index: usize,

    pub fn init(source: []const u8) Lexer {
        return .{
            .source = source,
            .line = 0,
            .column = 0,
            .start_index = 0,
            .current_index = 0,
        };
    }

    pub fn isAtEnd(self: Lexer) bool {
        return self.current_index >= self.source.len;
    }

    fn advance(self: *Lexer) void {
        if (self.peek() == '\n') {
            self.line += 1;
            self.column = 0;
        } else {
            self.column += 1;
        }
        self.current_index += 1;
        if (self.isAtEnd()) self.current_index = self.source.len;
    }

    fn peek(self: Lexer) u8 {
        return if (self.current_index < self.source.len) self.source[self.current_index] else 0;
    }

    fn discard(self: *Lexer) void {
        self.start_index = self.current_index;
    }

    fn token(self: Lexer, token_type: Token.Type) Token {
        return .{
            .type = token_type,
            .value = self.source[self.start_index..self.current_index],
            .line = self.line,
            .column = self.column + self.start_index - self.current_index,
        };
    }

    fn errorToken(self: Lexer, message: []const u8) Token {
        return .{
            .type = .error_,
            .value = message,
            .line = self.line,
            .column = self.column,
        };
    }

    fn isLiteral(c: u8) bool {
        return switch (c) {
            ' ', '\t', '\r', '\n', '(', ')', ';', 0 => false,
            else => true,
        };
    }

    fn literal(self: *Lexer) Token {
        while (isLiteral(self.peek())) self.advance();
        return self.token(.literal);
    }

    fn string(self: *Lexer) Token {
        // discard opening quote
        self.discard();

        while (self.peek() != '"' and !self.isAtEnd()) self.advance();

        if (self.isAtEnd()) return self.errorToken("unterminated string");

        const tok = self.token(.string);

        // discard closing quote
        self.advance();
        self.discard();

        return tok;
    }

    pub fn lexToken(self: *Lexer) Token {
        self.discard();

        while (!self.isAtEnd()) {
            const c = self.peek();
            self.advance();

            switch (c) {
                ' ', '\t', '\r', '\n' => self.discard(),
                '(' => return self.token(.left_paren),
                ')' => return self.token(.right_paren),
                ';' => {
                    while (self.peek() != '\n' and !self.isAtEnd()) self.advance();
                    self.discard();
                },
                '"' => return self.string(),
                else => return self.literal(),
            }
        }

        return self.token(.eof);
    }
};
