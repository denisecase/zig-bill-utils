// stream/extract_money.zig - Extracts funding amounts from stdin, writes to stdout in CSV

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
            \\Usage: extract_money_stream [--help]
            \\
            \\Reads cleaned bill text from stdin and writes lines with
            \\funding amounts to stdout as CSV: amount,text
            \\
            \\Example:
            \\  cat clean.txt | extract_money_stream > money_lines.csv
            \\
        );
        return;
    }

    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    try stdout.writeAll("amount,text\n");

    var buf: [4096]u8 = undefined;
    var count: usize = 0;

    while (try utils.readLineTrimmed(stdin, &buf)) |line| {
        if (money.findMoney(line)) |amount| {
            try stdout.print("\"{s}\",\"{s}\"\n", .{ amount, line });
            count += 1;
        }
    }

    log.info(tool, try std.fmt.allocPrint(allocator, "Found {d} matches", .{count}));
    log.done(tool);
}
