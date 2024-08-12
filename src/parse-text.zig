const std = @import("std");
const time = std.time;
const Timer = time.Timer;
const print = std.debug.print;

pub fn parseFile(allocator: std.mem.Allocator, file_name: []const u8) !void {
    var timer = try Timer.start();

    // open the file
    var file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    // read the file contents into a buffer
    const file_contents = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(file_contents);

    _ = findInString(file_contents, "# Derived Property: ID_Start");
    print("Done\n", .{});
    const elapsed2: f64 = @floatFromInt(timer.read());
    print("Time elapsed is: {d:.3}ms\n", .{
        elapsed2 / time.ns_per_ms,
    });
}

const CHUNK_SIZE = 1024 * 1024; // 1MB

fn findInString(text: []const u8, target: []const u8) bool {
    var line: usize = 1;
    var found: bool = false;
    for (text, 0..) |char, index| {
        if (char == target[0]) {
            for (target, 1..) |_, i| {
                if (index + i >= text.len or target[i] != text[index + i]) {
                    break;
                }

                if (i == target.len - 1) {
                    found = true;
                    break;
                }
            }
        }
        if (char == '\n') {
            line += 1;
        }

        if (found) {
            break;
        }
    }
    return found;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try parseFile(allocator, "src/DerivedCoreProperties.txt");
}
