// extract_money.zig - Extracts funding amounts from a bill text file

const std = @import("std");
const log = @import("lib").logger;
const utils = @import("lib").utils;
const money = @import("lib").extract_money;

pub fn main() !void {
    const tool = "extract_money";
    log.start(tool);

    const allocator = std.heap.page_allocator;
    const args = try utils.parseArgs();

    if (utils.hasArg(args, "--help")) {
        try std.io.getStdOut().writer().writeAll(
            \\Usage: extract-money --path data/2025-hconres0014/clean.txt
            \\       extract-money --help
            \\
            \\Extracts funding amounts from a cleaned bill text file.
            \\Output format: CSV (amount,text)
            \\
            \\Output file: output/billname/money_lines.csv
            \\
        );
        return;
    }

    const input_path = try utils.requirePathArg(tool, args);
    const output_dir = try utils.resolveOutputDir(allocator, args, input_path);
    try std.fs.cwd().makePath(output_dir);

    const output_path = try utils.safeJoinPath(allocator, &.{ output_dir, "money_lines.csv" });
    const file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();
    const reader = file.reader();

    const out_file = try std.fs.cwd().createFile(output_path, .{ .truncate = true });
    defer out_file.close();
    const writer = out_file.writer();

    try writer.writeAll("amount,text\n");

    var buf: [4096]u8 = undefined;
    var line_num: usize = 0;
    var count: usize = 0;

    while (try utils.readLineTrimmed(reader, &buf)) |line| {
        line_num += 1;
        if (money.findMoney(line)) |amount| {
            try writer.print("\"{s}\",\"{s}\"\n", .{ amount, line });
            count += 1;
        }
    }

    log.info(tool, try std.fmt.allocPrint(allocator, "Found {d} matches", .{count}));
    log.done(tool);
}
