// extract_amendments.zig - Converts amendments.csv into .txt files per amendment

const std = @import("std");
const utils = @import("utils.zig");
const log = @import("logger.zig");

pub fn main() !void {
    const tool = "extract-amendments";
    log.start(tool);

    const allocator = std.heap.page_allocator;
    const args = try utils.parseArgs();

    if (utils.hasArg(args, "--help")) {
        try std.io.getStdOut().writer().writeAll(
            \\Usage: extract-amendments --path 2025-hconres0014 [--outdir output]
            \\       extract-amendments --help
            \\
            \\Reads amendments.csv from the data folder and writes one text file
            \\per amendment to the output/billname/amendments folder.
            \\
            \\Example:
            \\  extract-amendments --path 2025-hconres0014
            \\
        );
        return;
    }

    const bill_name = try utils.requirePathArg(tool, args);
    const output_root = try utils.resolveOutputDir(allocator, args, bill_name);

    const csv_path = try std.fs.path.join(allocator, &.{ bill_name, "amendments.csv" });
    const output_dir = try utils.safeJoinPath(allocator, &.{ output_root, "amendments" });
    try std.fs.cwd().makePath(output_dir);

    const file = try std.fs.cwd().openFile(csv_path, .{});
    defer file.close();

    var line_num: usize = 0;
    var file_count: usize = 0;

    var all_lines = std.ArrayList([]const u8).init(allocator);
    const full_buf = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(full_buf);

    var reader = std.mem.tokenizeScalar(u8, full_buf, '\n');
    while (reader.next()) |line| {
        try all_lines.append(line);
    }

    var i: usize = 0;
    while (i < all_lines.items.len) {
        var joined = all_lines.items[i];
        var quote_count = std.mem.count(u8, joined, "\"");

        // Merge following lines until we balance quotes
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

        // Combine all fields starting from index 9 as the full amendment body
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

        // Skip if not enough content
        if (amendment_number.len < 2 or body_final.len < 10) {
            log.caution(tool, try std.fmt.allocPrint(allocator, "Skipping amendment {s} on line {d} (too short)", .{ amendment_number, line_num }));
            continue;
        }

        const safe_name = try makeFilename(allocator, amendment_number);
        const out_path = try utils.safeJoinPath(allocator, &.{ output_dir, safe_name });
        const out_file = try std.fs.cwd().createFile(out_path, .{ .truncate = true });
        defer out_file.close();

        const writer = out_file.writer();
        try writer.print("Sponsor: {s}\nParty: {s}\n\n-- AMENDMENT TEXT --\n\n{s}\n", .{ sponsor, party, body_final });
        file_count += 1;
    }

    log.info(tool, try std.fmt.allocPrint(allocator, "Wrote {d} amendment files.", .{file_count}));
    log.done(tool);
}

fn makeFilename(allocator: std.mem.Allocator, amendment_id: []const u8) ![]const u8 {
    var buf = try allocator.alloc(u8, amendment_id.len);
    var j: usize = 0;
    for (amendment_id) |c| {
        if (std.ascii.isAlphanumeric(c)) {
            buf[j] = std.ascii.toLower(c);
            j += 1;
        }
    }
    return try std.fmt.allocPrint(allocator, "sa{0s}.txt", .{buf[0..j]});
}
