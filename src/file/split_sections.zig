// split_sections.zig - Splits bill text by section headings into separate files

const std = @import("std");
const log = @import("lib").logger;
const utils = @import("lib").utils;
const split_sections = @import("lib").split_sections;

pub fn main() !void {
    const tool = "split_sections";
    log.start(tool);

    const allocator = std.heap.page_allocator;
    const args = try utils.parseArgs();

    if (utils.hasArg(args, "--help")) {
        try std.io.getStdOut().writer().writeAll(
            \\Usage: split-sections --path data/2025-bill-name/clean.txt [--outdir folder]
            \\       split-sections --help
            \\
            \\Splits bill text by section headings into separate files.
            \\Default output directory: output/{billname}/sections/
            \\
        );
        return;
    }

    const input_path = try utils.requirePathArg(tool, args);
    const output_dir = try utils.resolveOutputDir(allocator, args, input_path);
    const outdir = try utils.safeJoinPath(allocator, &.{ output_dir, "sections" });
    try std.fs.cwd().makePath(outdir);

    const file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();
    const reader = file.reader();

    const fs = std.fs.cwd();
    var buf: [4096]u8 = undefined;
    var writer: ?std.fs.File.Writer = null;

    var current_section_name: []const u8 = "preamble";
    var last_section_name: []const u8 = current_section_name;

    var path_buf: [512]u8 = undefined;
    var out_file = try split_sections.openSectionFile(fs, outdir, current_section_name, &path_buf);
    writer = out_file.writer();

    while (try utils.readLineTrimmed(reader, &buf)) |line| {
        var lower_buf: [4096]u8 = undefined;
        const lower = utils.toLowerInPlace(line, &lower_buf);

        if (split_sections.isHeading(lower)) {
            var label_buf: [256]u8 = undefined;
            const new_section = split_sections.sanitizeHeadingName(line, &label_buf);

            if (!std.mem.eql(u8, new_section, last_section_name)) {
                out_file.close();
                path_buf = undefined;
                out_file = try split_sections.openSectionFile(fs, outdir, new_section, &path_buf);
                log.info(tool, try std.fmt.allocPrint(allocator, "Writing: {s}.txt", .{new_section}));
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
