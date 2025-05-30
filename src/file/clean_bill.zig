// clean_bill.zig - Cleans bill text files

const std = @import("std");
const log = @import("lib").logger;
const utils = @import("lib").utils;
const clean_bill = @import("lib").clean_bill;

pub fn main() !void {
    const tool = "clean_bill";
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
        const cleaned = clean_bill.stripLineNumbers(line);
        try writer.writeAll(cleaned);
        try writer.writeByte('\n');
    }

    log.done(tool);
}
