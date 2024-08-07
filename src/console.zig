const std = @import("std");
const Ansi = @import("./ansi.zig").Ansi;
const AnsiColor = @import("./ansi.zig").AnsiColor;
const WriterType = @TypeOf(std.io.getStdOut().writer());

pub const Console = struct {
    writer: WriterType = std.io.getStdOut().writer(),

    pub fn init() Console { // Use type inference
        const writer = std.io.getStdOut().writer();
        return Console{ .writer = writer };
    }

    pub fn write(self: *Console, comptime format: []const u8, args: anytype, color: ?AnsiColor) !void {
        var ansi_color = Ansi{ .color = AnsiColor.white }; // Default color
        if (color) |c| {
            ansi_color = Ansi{ .color = c };
        }
        const color_code = ansi_color.toCode();
        const reset = Ansi{ .color = AnsiColor.reset };

        // Create a formatted message using the provided format and arguments
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer std.debug.assert(gpa.deinit() == .ok);
        const allocator = gpa.allocator();

        var buffer = try std.fmt.allocPrint(allocator, format, args);
        defer allocator.free(buffer);

        // Print the formatted message with color codes
        try self.writer.print("{s}{s}{s}\n", .{ color_code, buffer, reset.toCode() });
    }
};

pub fn main() !void {
    var console = Console.init();

    try console.write("Hello, World!", AnsiColor.red);
}
