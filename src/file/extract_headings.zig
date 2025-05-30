// extract_headings.zig - Extracts section headings from a bill text file

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
            \\Usage: extract-headings --path data/2025-hconres0014/clean.txt
            \\       extract-headings --help
            \\
            \\Extracts section headers from cleaned legislative bill text.
            \\Common matches include:
            \\  TITLE I—GENERAL PROVISIONS
            \\  SEC. 101. SHORT TITLE
            \\  Section 305. Definitions
            \\
        );
        return;
    }

    const input_path = try utils.requirePathArg(tool, args);
    const output_dir = try utils.resolveOutputDir(allocator, args, input_path);
    try std.fs.cwd().makePath(output_dir);

    const file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();
    const reader = file.reader();

    const headings_out_path = try utils.safeJoinPath(allocator, &.{ output_dir, "headings.txt" });
    const out_file = try std.fs.cwd().createFile(headings_out_path, .{ .truncate = true });
    defer out_file.close();
    const writer = out_file.writer();

    var buf: [4096]u8 = undefined;
    var count: usize = 0;

    while (try utils.readLineTrimmed(reader, &buf)) |line| {
        const lower = try utils.toLowerAlloc(allocator, line);
        defer allocator.free(lower);

        if (headings.isHeading(lower)) {
            try writer.print("{s}\n", .{line});
            count += 1;
        }
    }

    log.info(tool, try std.fmt.allocPrint(allocator, "Found {d} headings", .{count}));
    log.done(tool);
}
