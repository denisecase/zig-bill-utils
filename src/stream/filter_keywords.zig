// stream/filter_keywords.zig - Filters stdin based on keywords, outputs grouped matches

const std = @import("std");
const log = @import("lib").logger;
const utils = @import("lib").utils;
const filter_keywords =  @import("lib").filter_keywords;

pub fn main() !void {
    const tool = "filter_keywords";
    log.start(tool);

    const allocator = std.heap.page_allocator;
    const args = try utils.parseArgs();

    if (utils.hasArg(args, "--help")) {
        try std.io.getStdOut().writer().writeAll(
            \\Usage: filter_keywords_stream [--keywords word1,word2,...]
            \\                              [--keyword-file path1 --keyword-file path2]
            \\
            \\Reads bill text from stdin and groups matching lines under keyword headings.
            \\Output is written to stdout.
            \\
            \\Example:
            \\  cat clean.txt | filter_keywords_stream --keywords fund,education
            \\
        );
        return;
    }

    // No input path needed — we'll read from stdin
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    // Read all input
    const content = try stdin.readAllAlloc(allocator, 65536);
    defer allocator.free(content);

    // Dummy path to satisfy the loader's fallback path logic
    const dummy_input_path = "stream_mode_input.txt";

    // Load keywords from args or fallback
    var keyword_list = try filter_keywords.collectKeywords(allocator, args, dummy_input_path);
    if (keyword_list.len == 0) {
        log.caution(tool, "No keywords provided. Using fallback: fund");
        var fallback = [_][]const u8{"fund"};
        keyword_list = fallback[0..];
    }

    const hits = try filter_keywords.searchAndWriteGroupedHits(allocator, stdout, content, keyword_list, "STDIN", tool, false);

    log.info(tool, try std.fmt.allocPrint(allocator, "Total grouped matches: {d}", .{hits}));
    log.done(tool);
}
