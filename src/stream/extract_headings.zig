// stream/extract_headings.zig - Extracts section headings from stdin

const std = @import("std");
const log = @import("lib").logger;
const utils = @import("lib").utils;
const headings = @import("lib").extract_headings;

pub fn main() !void {
    const tool = "extract_headings";
    log.start(tool);

    const allocator = std.heap.page_allocator;
    const args = try utils.parseArgs();

    if (utils.hasArg(args, "--help")) {
        try std.io.getStdOut().writer().writeAll(
            \\Usage: extract_headings_stream [--help]
            \\
            \\Reads bill text from stdin and writes recognized section headings to stdout.
            \\Common matches include:
            \\  TITLE I—GENERAL PROVISIONS
            \\  SEC. 101. SHORT TITLE
            \\  Section 305. Definitions
            \\
            \\Example:
            \\  cat clean.txt | extract_headings_stream > headings.txt
            \\
        );
        return;
    }

    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    var buf: [4096]u8 = undefined;
    var count: usize = 0;

    while (try utils.readLineTrimmed(stdin, &buf)) |line| {
        const lower = try utils.toLowerAlloc(allocator, line);
        defer allocator.free(lower);

        if (headings.isHeading(lower)) {
            try stdout.print("{s}\n", .{line});
            count += 1;
        }
    }

    log.info(tool, try std.fmt.allocPrint(allocator, "Found {d} headings", .{count}));
    log.done(tool);
}
