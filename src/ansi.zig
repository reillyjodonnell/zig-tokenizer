pub const AnsiColor = enum {
    reset,
    bold,
    underline,
    inverse,
    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
};

pub const Ansi = struct {
    color: AnsiColor,
    reset: []const u8 = "\x1b[0m",
    bold: []const u8 = "\x1b[1m",
    underline: []const u8 = "\x1b[4m",
    inverse: []const u8 = "\x1b[7m",
    black: []const u8 = "\x1b[30m",
    red: []const u8 = "\x1b[31m",
    green: []const u8 = "\x1b[32m",
    yellow: []const u8 = "\x1b[33m",
    blue: []const u8 = "\x1b[34m",
    magenta: []const u8 = "\x1b[35m",
    cyan: []const u8 = "\x1b[36m",
    white: []const u8 = "\x1b[37m",

    pub fn toCode(self: Ansi) []const u8 {
        return switch (self.color) {
            .reset => "\x1b[0m",
            .bold => "\x1b[1m",
            .underline => "\x1b[4m",
            .inverse => "\x1b[7m",
            .black => "\x1b[30m",
            .red => "\x1b[31m",
            .green => "\x1b[32m",
            .yellow => "\x1b[33m",
            .blue => "\x1b[34m",
            .magenta => "\x1b[35m",
            .cyan => "\x1b[36m",
            .white => "\x1b[37m",
        };
    }
};
