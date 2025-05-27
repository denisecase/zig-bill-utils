// clean_bill.zig - Cleans bill text files

const std = @import("std");
const log = @import("logger.zig");
const utils = @import("utils.zig");

pub fn main() !void {
    const tool = "clean-bill";
    log.start(tool);

    const allocator = std.heap.page_allocator;
    const args = try utils.parseArgs();

    if (utils.hasArg(args, "--help")) {
        try std.io.getStdOut().writer().writeAll(
            \\Usage: bill-clean --path data/2025-hconres0014/bill.txt
            \\       bill-clean --help
            \\
            \\Reads a bill text file and removes:
            \\- Leading line numbers (e.g., '1234 Sec.')
            \\- Extra whitespace
            \\
            \\Outputs cleaned text to stdout.
            \\
            \\Example:
            \\  bill-clean --path data/2025-hconres0014/bill.txt > clean.txt
            \\
        );
        return;
    }

    const input_path = try utils.requirePathArg(tool, args);
    const output_dir = try utils.resolveOutputDir(allocator, args, input_path);
    try std.fs.cwd().makePath(output_dir);
    log.info(tool, try std.fmt.allocPrint(allocator, "Writing to: {s}", .{output_dir}));

    const file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();
    const reader = file.reader();

    const output_path = try std.fs.path.join(allocator, &.{ output_dir, "clean.txt" });
    const out_file = try std.fs.cwd().createFile(output_path, .{ .truncate = true });
    defer out_file.close();
    const writer = out_file.writer();
    
    var buf: [4096]u8 = undefined;

    while (try utils.readLineTrimmed(reader, &buf)) |line| {
        const cleaned = stripLineNumbers(line);
        try writer.writeAll(cleaned);
        try writer.writeByte('\n');
    }

    log.done(tool);
}

fn stripLineNumbers(line: []const u8) []const u8 {
    var i: usize = 0;
    while (i < line.len and std.ascii.isDigit(line[i])) : (i += 1) {}
    if (i < line.len and (line[i] == '.' or line[i] == ' ')) i += 1;
    return line[i..];
}
