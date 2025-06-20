// stream/extract_amendments.zig - Converts CSV from stdin into .txt files per amendment

const std = @import("std");
const log = @import("lib").logger;
const utils = @import("lib").utils;
const extract_amendments = @import("lib").extract_amendments;

pub fn main() !void {
    const tool = "extract_amendments";
    log.start(tool);

    const allocator = std.heap.page_allocator;
    const args = try utils.parseArgs();

    if (utils.hasArg(args, "--help")) {
        try std.io.getStdOut().writer().writeAll(
            \\Usage: extract_amendments_stream [--outdir output/billname/amendments]
            \\       extract_amendments_stream --help
            \\
            \\Reads amendments.csv content from stdin and writes one text file
            \\per amendment to the specified --outdir folder.
            \\
            \\Example:
            \\  cat data/2025-hconres0014/amendments.csv | extract_amendments_stream --outdir output/2025-hconres0014/amendments
            \\
        );
        return;
    }

    const out_dir = utils.getArgValue(args, "--outdir") orelse {
        log.fail(tool, "Missing required --outdir argument.");
        return error.MissingArgument;
    };

    try std.fs.cwd().makePath(out_dir);

    const stdin = std.io.getStdIn().reader();
    const contents = try stdin.readAllAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(contents);

    var all_lines = std.ArrayList([]const u8).init(allocator);
    var reader = std.mem.tokenizeScalar(u8, contents, '\n');
    while (reader.next()) |line| {
        try all_lines.append(line);
    }

    var line_num: usize = 0;
    var file_count: usize = 0;

    var i: usize = 0;
    while (i < all_lines.items.len) {
        var joined = all_lines.items[i];
        var quote_count = std.mem.count(u8, joined, "\"");

        while (quote_count % 2 != 0 and i + 1 < all_lines.items.len) {
            i += 1;
            joined = try std.fmt.allocPrint(allocator, "{s}\n{s}", .{ joined, all_lines.items[i] });
            quote_count = std.mem.count(u8, joined, "\"");
        }

        i += 1;
        line_num += 1;
        if (line_num < 4) continue;

        var splitter = std.mem.splitScalar(u8, joined, ',');
        var fields = std.ArrayList([]const u8).init(allocator);
        defer fields.deinit();

        while (splitter.next()) |field| {
            try fields.append(field);
        }

        if (fields.items.len < 11) {
            log.caution(tool, try std.fmt.allocPrint(allocator, "Skipping line {d} (only {d} fields)", .{ line_num, fields.items.len }));
            continue;
        }

        const amendment_number = std.mem.trim(u8, fields.items[1], " \"");
        const sponsor = std.mem.trim(u8, fields.items[4], " \"");
        const party = std.mem.trim(u8, fields.items[5], " \"");

        var body_full = std.ArrayList(u8).init(allocator);
        defer body_full.deinit();

        for (fields.items[9..]) |field| {
            const trimmed = std.mem.trim(u8, field, " \"");
            if (trimmed.len > 0) {
                if (body_full.items.len > 0) try body_full.appendSlice("\n");
                try body_full.appendSlice(trimmed);
            }
        }

        const body_final = body_full.items;

        if (amendment_number.len < 2 or body_final.len < 10) {
            log.caution(tool, try std.fmt.allocPrint(allocator, "Skipping amendment {s} on line {d} (too short)", .{ amendment_number, line_num }));
            continue;
        }

        const safe_name = try extract_amendments.makeFilename(allocator, amendment_number);
        const out_path = try utils.safeJoinPath(allocator, &.{ out_dir, safe_name });
        const out_file = try std.fs.cwd().createFile(out_path, .{ .truncate = true });
        defer out_file.close();

        const writer = out_file.writer();
        try writer.print("Sponsor: {s}\nParty: {s}\n\n-- AMENDMENT TEXT --\n\n{s}\n", .{ sponsor, party, body_final });
        file_count += 1;
    }

    log.info(tool, try std.fmt.allocPrint(allocator, "Wrote {d} amendment files.", .{file_count}));
    log.done(tool);
}
