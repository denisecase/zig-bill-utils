// src/lib/filter_keywords.zig
const std = @import("std");
const log = @import("logger.zig");
const utils = @import("utils.zig");

pub fn searchAndWriteGroupedHits(
    allocator: std.mem.Allocator,
    writer: anytype,
    content: []const u8,
    keywords: [][]const u8,
    source_label: []const u8,
    log_prefix: []const u8,
    omit_empty_headings: bool
) !usize {
    var total_matches: usize = 0;
    var all_hits: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);

    for (keywords) |keyword| {
        var line_iter = std.mem.splitScalar(u8, content, '\n');
        const lower_keyword = try utils.toLowerAlloc(allocator, keyword);
        defer allocator.free(lower_keyword);

        var found_any = false;
        while (line_iter.next()) |line| {
            const lower_line = try utils.toLowerAlloc(allocator, line);
            defer allocator.free(lower_line);
            if (std.mem.indexOf(u8, lower_line, lower_keyword) != null) {
                found_any = true;
                break;
            }
        }

        if (!found_any and omit_empty_headings) continue;

        try all_hits.append(try std.fmt.allocPrint(allocator, "=== {s} ===\n", .{keyword}));

        line_iter = std.mem.splitScalar(u8, content, '\n');
        while (line_iter.next()) |line| {
            const lower_line = try utils.toLowerAlloc(allocator, line);
            defer allocator.free(lower_line);
            if (std.mem.indexOf(u8, lower_line, lower_keyword) != null) {
                try all_hits.append(try allocator.dupe(u8, line));
                total_matches += 1;
            }
        }

        if (!found_any) {
            try all_hits.append("(none)");
        }

        try all_hits.append(""); // newline
    }

    if (total_matches > 0) {
        try writer.print("### {s} ###\n", .{source_label});
        for (all_hits.items) |line| {
            try writer.print("{s}\n", .{line});
        }
    }

    const summary_label = try std.fmt.allocPrint(allocator, "{s} [{s}]", .{ log_prefix, source_label });
    log.info(summary_label, try std.fmt.allocPrint(allocator, "Total matches: {d}", .{total_matches}));

    return total_matches;
}

pub fn collectKeywords(
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
