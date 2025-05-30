// filter_keywords.zig - Filters lines from bill text and amendments based on keywords, grouped by keyword

const std = @import("std");
const log = @import("lib").logger;
const utils = @import("lib").utils;
const filter_keywords = @import("lib").filter_keywords;

pub fn main() !void {
    const tool = "filter_keywords";
    log.start(tool);

    const allocator = std.heap.page_allocator;
    const args = try utils.parseArgs();

    if (utils.hasArg(args, "--help")) {
        try std.io.getStdOut().writer().writeAll(
            \\Usage: filter-keywords --path data/bill-folder/clean.txt
            \\                       [--keywords word1,word2,...]
            \\                       [--keyword-file path1 --keyword-file path2]
            \\Output:
            \\  output/{bill}/keyword_hits.txt
            \\  output/{bill}/keyword_hits_amendments.txt
        );
        return;
    }

    const input_path = try utils.requirePathArg(tool, args);
    const output_dir = try utils.resolveOutputDir(allocator, args, input_path);
    try std.fs.cwd().makePath(output_dir);

    // Load keywords
    var keyword_list = try filter_keywords.collectKeywords(allocator, args, input_path);
    if (keyword_list.len == 0) {
        log.caution(tool, "No keywords provided. Using fallback: fund");
        var fallback_keywords = [_][]const u8{"fund"};
        keyword_list = fallback_keywords[0..];
    }

    // === PART 1: Main Bill Text ===
    const bill_output_path = try utils.safeJoinPath(allocator, &.{ output_dir, "keyword_hits.txt" });
    const bill_output_file = try std.fs.cwd().createFile(bill_output_path, .{ .truncate = true });
    defer bill_output_file.close();
    const bill_writer = bill_output_file.writer();

    const raw_file = try std.fs.cwd().openFile(input_path, .{});
    defer raw_file.close();
    const full_input = try raw_file.readToEndAlloc(allocator, 65536);
    defer allocator.free(full_input);

    const bill_hits = try filter_keywords.searchAndWriteGroupedHits(allocator, bill_writer, full_input, keyword_list, "BILL TEXT", tool, false);

    // === PART 2: Amendment Texts ===
    const amendment_folder = try std.fs.path.join(allocator, &.{ output_dir, "amendments" });

    const amend_output_path = try utils.safeJoinPath(allocator, &.{ output_dir, "keyword_hits_amendments.txt" });
    const amend_file = try std.fs.cwd().createFile(amend_output_path, .{ .truncate = true });
    defer amend_file.close();
    const amend_writer = amend_file.writer();

    var amend_hits: usize = 0;
    var dir = try std.fs.cwd().openDir(amendment_folder, .{ .iterate = true });
    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind != .file or !std.mem.endsWith(u8, entry.name, ".txt")) continue;

        const amend_path = try std.fs.path.join(allocator, &.{ amendment_folder, entry.name });
        const amend_input_file = try std.fs.cwd().openFile(amend_path, .{});
        defer amend_input_file.close();
        const contents = try amend_input_file.readToEndAlloc(allocator, 65536);
        defer allocator.free(contents);

        try amend_writer.print("### {s} ###\n\n", .{entry.name});
        const hits = try filter_keywords.searchAndWriteGroupedHits(allocator, amend_writer, contents, keyword_list, entry.name, tool, true);
        amend_hits += hits;
    }

    const total = bill_hits + amend_hits;
    const msg = try std.fmt.allocPrint(allocator, "Total grouped matches: {d}", .{total});
    log.info(tool, msg);
    log.done(tool);
}
