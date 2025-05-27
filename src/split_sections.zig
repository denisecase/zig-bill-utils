// split_sections.zig - Splits bill text by section headings into separate files

const std = @import("std");
const log = @import("logger.zig");
const utils = @import("utils.zig");

pub fn main() !void {
    const tool = "split-sections";
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
    var out_file = try openSectionFile(fs, outdir, current_section_name, &path_buf);
    log.info(tool, try std.fmt.allocPrint(allocator, "Writing: {s}.txt", .{current_section_name}));
    writer = out_file.writer();

    while (try utils.readLineTrimmed(reader, &buf)) |line| {
        var lower_buf: [4096]u8 = undefined;
        const lower = utils.toLowerInPlace(line, &lower_buf);

        if (isHeading(lower)) {
            var label_buf: [256]u8 = undefined;
            const new_section = sanitizeHeadingName(line, &label_buf);

            if (!std.mem.eql(u8, new_section, last_section_name)) {
                out_file.close();
                path_buf = undefined;
                out_file = try openSectionFile(fs, outdir, new_section, &path_buf);
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

fn isHeading(line: []const u8) bool {
    return std.mem.startsWith(u8, line, "title ") or
        std.mem.startsWith(u8, line, "sec.") or
        std.mem.startsWith(u8, line, "section ");
}

fn sanitizeHeadingName(raw: []const u8, buf: *[256]u8) []const u8 {
    var j: usize = 0;
    for (raw) |c| {
        if (j >= buf.len) break;
        buf[j] = if (std.ascii.isAlphanumeric(c))
            std.ascii.toLower(c)
        else if (c == ' ' or c == '-')
            '-'
        else
            continue;
        j += 1;
    }
    return buf[0..j];
}

fn openSectionFile(fs_dir: std.fs.Dir, outdir: []const u8, label: []const u8, path_buf: *[512]u8) !std.fs.File {
    const name_slice = try std.fmt.bufPrint(path_buf, "{s}/{s}.txt", .{ outdir, label });
    return try fs_dir.createFile(name_slice, .{ .truncate = true });
}
