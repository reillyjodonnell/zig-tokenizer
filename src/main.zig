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

    for (list.items) |item| {
        print("{c}\n", .{item});
    }

    // try fs.fileReader("src/index.html");
}
