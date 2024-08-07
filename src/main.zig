const std = @import("std");
const fs = @import("./file-reader.zig");
const print = std.debug.print;

//https://tc39.es/ecma262/#prod-UnicodeIDStart

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    const html_content = @embedFile("index.html");

    for (html_content) |char| {
        try list.append(char);
    }
}

// TOKEN

const TokenType = enum {
    RESERVED_WORD,
    IDENTIFIER,
    LINE_TERMINATOR,
    SINGLE_LINE_COMMENT,
    MULTI_LINE_COMMENT,
    EOF,
    WHITE_SPACE,

    // literals
    NULL,
    STRING,
    NUMBER,
    BOOLEAN,
    REGULAR_EXPRESSION,
};

const Token = struct {
    type: TokenType,
    data: []const u8,
    column: usize,
    line: usize,

    pub fn init(token_type: TokenType, data: []const u8) Token {
        return Token{ .type = token_type, .data = data, .column = 0, .line = 0 };
    }
};

// TOKENIZER

// COMMENTS
const CommentError = error{
    SINGLE_LINE_COMMENT_NOT_CLOSED,
};

const State = enum {
    InputElementHashbangOrRegExp,
    InputElementDiv,
    InputElementRegExp,
    InputElementRegExpOrTemplateTail,
    InputElementTemplateTail,
};

const Context = struct {
    data: []const u8,
    index: usize,
    start_index: usize,
    column: usize,
    tokens: std.ArrayList(Token),
    reserved_words_map: std.StringHashMap(bool),
    active_type: ActiveType,
    active_type_in_progress: bool,
};

const ActiveType = enum {
    NONE,
    SINGLE_LINE_COMMENT,
    MULTI_LINE_COMMENT,
    SINGLE_QUOTE_STRING,
    DOUBLE_QUOTE_STRING,
    NUMBER,
    REGULAR_EXPRESSION,
};

const Possibilities = enum {
    Comment,
    String,
};

const Tokenizer = struct {
    state: State,
    context: Context,

    pub fn init(data: []const u8, allocator: std.mem.Allocator) !Tokenizer {
        print("Data received: {s}\n", .{data});
        var reserved_words_map = std.StringHashMap(bool).init(allocator);
        for (reserved_words) |word| {
            try reserved_words_map.put(word, true);
        }
        return Tokenizer{
            .state = State.InputElementHashbangOrRegExp,
            .context = Context{
                .data = data,
                .index = 0,
                .start_index = 0,
                .column = 0,
                .tokens = std.ArrayList(Token).init(allocator),
                .reserved_words_map = reserved_words_map,
                .active_type = ActiveType.NONE,
                .active_type_in_progress = false,
            },
        };
    }

    pub fn deinit(self: *Tokenizer) void {
        self.context.tokens.deinit();
        self.context.reserved_words_map.deinit();
    }

    pub fn isKeyword(self: *Tokenizer, lexeme: []const u8) bool {
        return self.context.reserved_words_map.get(lexeme) != null;
    }

    pub fn tokenize(self: *Tokenizer) !std.ArrayList(Token) {
        //https://unicode.org/Public/UCD/latest/ucd/PropList.txt
        while (!self.isEOF()) {
            const char = self.context.data[self.context.index];
            print("character is {c}\n", .{char});
            switch (self.state) {
                State.InputElementHashbangOrRegExp => {
                    try self.handleInputElementHashbangOrRegExp(char);
                },
                State.InputElementDiv => {},
                State.InputElementRegExp => {},
                State.InputElementRegExpOrTemplateTail => {},
                State.InputElementTemplateTail => {},
            }
            try self.processChar(char);
            self.advance();
        }
        print("EOF\n", .{});

        return self.context.tokens;
    }

    fn handleInputElementHashbangOrRegExp(self: *Tokenizer, char: u8) !void {
        //https://tc39.es/ecma262/#prod-InputElementHashbangOrRegExp
        switch (@as(u32, char)) {
            // WHITESPACE
            //https://tc39.es/ecma262/#sec-white-space
            //https://tc39.es/ecma262/#table-white-space-code-points
            0x0009,
            0x000B,
            0x000C,
            0xFEFF,
            // TODO: any code point in general category “Space_Separator”
            => {
                self.state = State.InputElementDiv;
                try self.context.tokens.append(Token.init(TokenType.WHITE_SPACE, self.context.data[self.context.index .. self.context.index + 1]));
                return;
            },

            // LINE_TERMINATOR
            // https://tc39.es/ecma262/#sec-line-terminators
            // https://tc39.es/ecma262/#table-line-terminator-code-points
            0x000A, 0x000D, 0x2028, 0x2029 => {
                self.context.column += 1;
                try self.context.tokens.append(Token.init(TokenType.LINE_TERMINATOR, self.context.data[self.context.index .. self.context.index + 1]));
                if (self.context.active_type == ActiveType.SINGLE_LINE_COMMENT) {
                    self.context.active_type = ActiveType.NONE;
                    try self.context.tokens.append(Token.init(TokenType.SINGLE_LINE_COMMENT, self.context.data[self.context.start_index - 1 .. self.context.index]));
                    try self.context.tokens.append(Token.init(TokenType.LINE_TERMINATOR, self.context.data[self.context.start_index .. self.context.index + 1]));
                    return;
                }
                return;
            },

            // COMMENT
            //https://tc39.es/ecma262/#sec-comments
            '/' => {
                const next_char = self.peek();
                if (next_char == '/') {
                    // this is a single line comment
                    self.context.start_index = self.context.index;
                    self.context.active_type = ActiveType.SINGLE_LINE_COMMENT;
                    self.context.active_type_in_progress = true;
                    self.advance();
                    self.advance();
                }
                if (next_char == '*') {
                    // this is a multi line comment
                    self.context.start_index = self.context.index;
                    self.context.active_type = ActiveType.MULTI_LINE_COMMENT;
                    self.context.active_type_in_progress = true;
                    self.advance();
                    self.advance();

                    // do we need to handle that it's not closed yet?
                }
            },
            '*' => {
                const next_char = self.peek();
                if (next_char == '/') {
                    // this is a multi line comment
                    self.context.active_type = ActiveType.NONE;
                    try self.context.tokens.append(Token.init(TokenType.MULTI_LINE_COMMENT, self.context.data[self.context.start_index .. self.context.index + 1]));
                    self.advance();
                    self.advance();
                    return;
                }
            },
            else => {},
        }
    }

    pub fn advance(self: *Tokenizer) void {
        self.context.index += 1;
    }

    pub fn processChar(self: *Tokenizer, char: u8) !void {
        _ = char;

        // check if a ID_START unicode character
        // https://github.com/rust-lang/rust/pull/33098
        // https://www.unicode.org/Public/UNIDATA/DerivedCoreProperties.txt

        // check if the word is a reserved word
        if (self.isKeyword(self.context.data[self.context.start_index .. self.context.index + 1])) {
            const token = Token.init(TokenType.RESERVED_WORD, self.context.data[self.context.start_index .. self.context.index + 1]);
            try self.context.tokens.append(token);
            self.context.start_index = self.context.index + 1;
            return;
        }
        return;
    }

    pub fn peek(self: *Tokenizer) ?u8 {
        if (self.context.index + 1 >= self.context.data.len) {
            return null;
        }
        return self.context.data[self.context.index + 1];
    }

    pub fn isEOF(self: *Tokenizer) bool {
        return self.context.index >= self.context.data.len;
    }
};

// test "Tokenizer" {
//     const data = "var";
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//     const allocator = gpa.allocator();
//     var tokenizer = try Tokenizer.init(data, allocator);
//     const tokens = try tokenizer.tokenize();
//     defer tokenizer.deinit();
//     try std.testing.expectEqualStrings("var", tokens.items[0].data);
// }

// test "recognize reserved words" {
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//     const allocator = gpa.allocator();
//     var tokenizer = try Tokenizer.init("const function var", allocator);
//     const tokens = try tokenizer.tokenize();
//     defer tokenizer.deinit();
//     // token should be a reserved word with the data "var"
//     const first_token = tokens.items[0];
//     try std.testing.expectEqualStrings("const", first_token.data);
//     try std.testing.expectEqual(TokenType.RESERVED_WORD, first_token.type);
//     const second_token = tokens.items[1];
//     try std.testing.expectEqualStrings("function", second_token.data);
//     try std.testing.expectEqual(TokenType.RESERVED_WORD, second_token.type);
//     const third_token = tokens.items[2];
//     try std.testing.expectEqualStrings("var", third_token.data);
//     try std.testing.expectEqual(TokenType.RESERVED_WORD, third_token.type);
// }

test "recognized single line comment" {
    const test_allocator = std.testing.allocator;
    var tokenizer = try Tokenizer.init("// this is a single line comment", test_allocator);
    const tokens = try tokenizer.tokenize();
    defer tokenizer.deinit();
    try std.testing.expectEqualStrings("// this is a single line comment", tokens.items[0].data);
    try std.testing.expectEqual(TokenType.SINGLE_LINE_COMMENT, tokens.items[0].type);
    try std.testing.expectEqualStrings(" this is a single line comment", tokens.items[1].data);

    try std.testing.expectEqual(TokenType.LINE_TERMINATOR, tokens.items[1].type);
    try std.testing.expectEqualStrings("\n", tokens.items[1].data);
}
// list of reserved words
const reserved_words = [_][]const u8{ "await", "break", "case", "catch", "class", "const", "continue", "debugger", "default", "delete", "do", "else", "enum", "export", "extends", "false", "finally", "for", "function", "if", "import", "in", "instanceof", "new", "null", "return", "super", "switch", "this", "throw", "true", "try", "typeof", "var", "void", "while", "with", "yield" };

const spaces = [_]u8{ ' ', '\t', '\n', '\r' };

// usage for comparison @as(u32, char) == 0x0009
const white_spaces_code_points = [_]u8{ 0x0009, 0x000B, 0x000C, 0xFEFF };

const line_terminators = [_]u8{ '\n', '\r' };
