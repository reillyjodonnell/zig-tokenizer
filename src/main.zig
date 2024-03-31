const std = @import("std");
const fs = @import("./file-reader.zig");

pub fn main() !void {
    try fs.fileReader("src/index.html");
}
