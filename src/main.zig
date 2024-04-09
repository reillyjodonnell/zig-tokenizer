const std = @import("std");
const fs = @import("./file-reader.zig");
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    const html_content = @embedFile("index.html");

    for (html_content) |char| {
        try list.append(char);
    }

    for (list.items, 0..) |item, index| {
        const generated_token = try parseToken(list.items, item, index);
        print("character: {c}", .{generated_token.type});
    }
}

fn parseToken(items: []u8, item: u8, index: usize) !Token {
    _ = items;
    _ = index;

    return Token{ .type = item };
}

const Token = struct {
    type: u8,

    pub fn init(huh: u8) Token {
        return Token{ .type = huh };
    }
};

const ForceQuirks = enum {
    on,
    off,
};

//DOCTYPE, start tag, end tag, comment, character, end-of-file
const Doctype = struct {
    name: []const u8,
    public_identifier: u8,
    systems_identifier: u8,
    force_quirks: ForceQuirks,
};

const StartTag = struct {};

const EndTag = struct {};

const Comment = struct {};

const Character = struct {};

const EndOfFile = struct {};
