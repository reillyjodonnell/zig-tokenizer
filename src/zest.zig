const std = @import("std");
const builtin = @import("builtin");
const Console = @import("./console.zig").Console;
const AnsiColor = @import("./ansi.zig").AnsiColor;

const ESC = "\x1b";
pub fn main() !void {
    var zest = Zest.init();
    try zest.execute();
}

const Zest = struct {
    console: Console,
    total_tests: usize = 0,
    total_passed: usize = 0,
    total_failed: usize = 0,
    total_elapsed: i64 = 0,
    start_time: i64 = 0,
    end_time: i64 = 0,

    pub fn init() Zest {
        return Zest{ .console = Console.init() };
    }

    pub fn execute(self: *Zest) !void {
        self.total_tests = builtin.test_functions.len;
        self.start_time = std.time.milliTimestamp();
        try self.console.write("Determining tests to run...\n", .{}, AnsiColor.black);
        for (builtin.test_functions) |t| {
            const name = extractName(t);
            try self.console.write("{s}[43mRUNS{s}[0m {s}\n", .{ ESC, ESC, name }, AnsiColor.white);
            const start = std.time.milliTimestamp();
            const result = t.func();

            if (result) |_| {
                const end = std.time.milliTimestamp();
                const elapsed: i64 = end - start;

                self.total_passed += 1;
                try self.console.write("✅ {s} passed - ({}ms)\n", .{ name, elapsed }, AnsiColor.green);
            } else |err| {
                const elapsed = std.time.milliTimestamp() - start;
                self.total_failed += 1;
                try self.console.write("❌ {s} failed - {} ({}ms)\n", .{ name, err, elapsed }, AnsiColor.red);
            }
        }

        // results
        self.total_elapsed = std.time.milliTimestamp() - self.start_time;
        try self.console.write("Total tests: {d}", .{self.total_tests}, AnsiColor.white);
        try self.console.write("Total passed: {d}", .{self.total_passed}, AnsiColor.green);
        try self.console.write("Total failed: {d}", .{self.total_failed}, AnsiColor.red);
        try self.console.write("Time: {d}ms\n", .{self.total_elapsed}, AnsiColor.white);
        try self.console.write("\nRan all test!\n", .{}, AnsiColor.black);
    }
};

fn extractName(t: std.builtin.TestFn) []const u8 {
    const marker = std.mem.lastIndexOf(u8, t.name, ".test.") orelse return t.name;
    return t.name[marker + 6 ..];
}
