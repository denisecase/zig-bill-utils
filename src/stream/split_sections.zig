// stream/split_sections.zig - Splits stdin bill text by section headings into separate files

const std = @import("std");
const log = @import("lib").logger;
const utils = @import("lib").utils;
const split_sections = @import("lib").split_sections;

pub fn main() !void {
    const tool = "split_sections";
    log.start(tool);

    const args = try utils.parseArgs();

    if (utils.hasArg(args, "--help")) {
        try std.io.getStdOut().writer().writeAll(
            \\Usage: split_sections_stream --outdir output/billname/sections
            \\
            \\Reads cleaned bill text from stdin and writes each section to a separate file.
            \\Files are written to the folder specified by --outdir.
            \\
            \\Example:
            \\  cat clean.txt | split_sections_stream --outdir output/2025-bill-name/sections
            \\
        );
        return;
    }

    const outdir = utils.getArgValue(args, "--outdir") orelse {
        log.fail(tool, "Missing required --outdir argument.");
        return error.MissingArgument;
    };

    try std.fs.cwd().makePath(outdir);
    const fs = std.fs.cwd();

    const stdin = std.io.getStdIn().reader();
    var buf: [4096]u8 = undefined;
    var writer: ?std.fs.File.Writer = null;

    var current_section_name: []const u8 = "preamble";
    var last_section_name: []const u8 = current_section_name;

    var path_buf: [512]u8 = undefined;
    var out_file = try split_sections.openSectionFile(fs, outdir, current_section_name, &path_buf);
    writer = out_file.writer();

    while (try utils.readLineTrimmed(stdin, &buf)) |line| {
        var lower_buf: [4096]u8 = undefined;
        const lower = utils.toLowerInPlace(line, &lower_buf);

        if (split_sections.isHeading(lower)) {
            var label_buf: [256]u8 = undefined;
            const new_section = split_sections.sanitizeHeadingName(line, &label_buf);

            if (!std.mem.eql(u8, new_section, last_section_name)) {
                out_file.close();
                path_buf = undefined;
                out_file = try split_sections.openSectionFile(fs, outdir, new_section, &path_buf);
                writer = out_file.writer();
                last_section_name = new_section;
            }

            current_section_name = new_section;
        }

        try writer.?.print("{s}\n", .{line});
    }

    out_file.close();
    log.done(tool);
}
