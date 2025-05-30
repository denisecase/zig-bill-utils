// stream/clean_bill.zig - Cleans bill text from stdin, writes to stdout

const std = @import("std");
const log = @import("lib").logger;
const utils = @import("lib").utils;
const clean_bill = @import("lib").clean_bill;

pub fn main() !void {
    const tool = "clean_bill";
    log.start(tool);

    const args = try utils.parseArgs();

    if (utils.hasArg(args, "--help")) {
        try std.io.getStdOut().writer().writeAll(
            \\Usage: clean_bill_stream [--help]
            \\
            \\Reads text from stdin and removes:
            \\- Leading line numbers (e.g., '1234 Sec.')
            \\- Extra whitespace
            \\
            \\Outputs cleaned text to stdout.
            \\
            \\Example:
            \\  cat bill.txt | clean_bill_stream > clean.txt
            \\
        );
        return;
    }

    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    var buf: [4096]u8 = undefined;

    while (try utils.readLineTrimmed(stdin, &buf)) |line| {
        const cleaned = clean_bill.stripLineNumbers(line);
        try stdout.writeAll(cleaned);
        try stdout.writeByte('\n');
    }

    log.done(tool);
}
