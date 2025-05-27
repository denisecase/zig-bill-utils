// filter_keywords.zig - Filters lines from bill text and amendments based on keywords, grouped by keyword

const std = @import("std");
const log = @import("logger.zig");
const utils = @import("utils.zig");

pub fn main() !void {
    const tool = "filter-keywords";
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
    var keyword_list = try collectKeywords(allocator, args, input_path);
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

    const bill_hits = try searchAndWriteGroupedHits(allocator, bill_writer, full_input, keyword_list, "BILL TEXT", tool, false);

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
        const hits = try searchAndWriteGroupedHits(allocator, amend_writer, contents, keyword_list, entry.name, tool, true);
        amend_hits += hits;
    }

    const total = bill_hits + amend_hits;
    const msg = try std.fmt.allocPrint(allocator, "Total grouped matches: {d}", .{total});
    log.info(tool, msg);
    log.done(tool);
}

fn searchAndWriteGroupedHits(
    allocator: std.mem.Allocator,
    writer: anytype,
    content: []const u8,
    keywords: [][]const u8,
    source_label: []const u8,
    log_prefix: []const u8,
    omit_empty_headings: bool
) !usize {
    var total_matches: usize = 0;

    for (keywords) |keyword| {
        var upper_buf: [256]u8 = undefined;
        const upper_keyword = std.ascii.upperString(&upper_buf, keyword);
        
        // Check first if there are any matches
        var found_any = false;
        var line_iter = std.mem.splitScalar(u8, content, '\n');
        while (line_iter.next()) |line| {
            const lower_line = try utils.toLowerAlloc(allocator, line);
            defer allocator.free(lower_line);
            const lower_keyword = try utils.toLowerAlloc(allocator, keyword);
            defer allocator.free(lower_keyword);

            if (std.mem.indexOf(u8, lower_line, lower_keyword) != null) {
                found_any = true;
                break;
            }
        }

        if (!found_any and omit_empty_headings) {
            continue;
        }

        // Reset iterator to print lines now
        line_iter = std.mem.splitScalar(u8, content, '\n');
        try writer.print("=== {s} ===\n", .{upper_keyword});
        
        const label = try std.fmt.allocPrint(allocator, "{s} [{s}]", .{ log_prefix, source_label });
        log.info(label, keyword);
        
        const lower_keyword = try utils.toLowerAlloc(allocator, keyword);
        defer allocator.free(lower_keyword);

        found_any = false;
        line_iter = std.mem.splitScalar(u8, content, '\n');
        while (line_iter.next()) |line| {
            const lower_line = try utils.toLowerAlloc(allocator, line);
            defer allocator.free(lower_line);

            if (std.mem.indexOf(u8, lower_line, lower_keyword) != null) {
                try writer.print("{s}\n", .{line});
                found_any = true;
                total_matches += 1;
            }
        }

        if (!found_any) {
            try writer.writeAll("(none)\n");
        }
        try writer.writeAll("\n");
    }

    return total_matches;
}

fn collectKeywords(
    allocator: std.mem.Allocator,
    args: []const []const u8,
    input_path: []const u8,
) ![][]const u8 {
    var all = std.ArrayList([]const u8).init(allocator);

    // Extract bill name from input path
    const parent = std.fs.path.dirname(input_path) orelse return error.InvalidPath;
    const bill_name = std.fs.path.basename(parent);
    const data_folder = try std.fmt.allocPrint(allocator, "data/{s}", .{bill_name});
    const kw_path = try std.fs.path.join(allocator, &.{ data_folder, "keywords.txt" });

    const terms = utils.readTermsFromFile(allocator, kw_path) catch {
        log.caution("filter-keywords", try std.fmt.allocPrint(allocator, "No keywords.txt in: {s}", .{data_folder}));
        return all.toOwnedSlice();
    };
    try all.appendSlice(terms);

    // Extra keyword files
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], "--keyword-file") and i + 1 < args.len) {
            const path = args[i + 1];
            i += 1;
            const terms_from_file = utils.readTermsFromFile(allocator, path) catch {
                log.caution("filter-keywords", try std.fmt.allocPrint(allocator, "Could not read keyword-file: {s}", .{path}));
                continue;
            };
            try all.appendSlice(terms_from_file);
        }
    }

    // Inline keywords
    if (utils.getArgValue(args, "--keywords")) |kwarg| {
        var splitter = std.mem.splitScalar(u8, kwarg, ',');
        while (splitter.next()) |kw| {
            const trimmed = std.mem.trim(u8, kw, " \t\r\n");
            if (trimmed.len > 0) {
                const copy = try allocator.dupe(u8, trimmed);
                try all.append(copy);
            }
        }
    }

    return all.toOwnedSlice();
}
