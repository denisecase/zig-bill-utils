// src/lib/split_sections.zig
const std = @import("std");
const log = @import("logger.zig");
const utils = @import("utils.zig");

pub fn isHeading(line: []const u8) bool {
    return std.mem.startsWith(u8, line, "title ") or
        std.mem.startsWith(u8, line, "sec.") or
        std.mem.startsWith(u8, line, "section ");
}

pub fn sanitizeHeadingName(raw: []const u8, buf: *[256]u8) []const u8 {
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

pub fn openSectionFile(fs_dir: std.fs.Dir, outdir: []const u8, label: []const u8, path_buf: *[512]u8) !std.fs.File {
    const name_slice = try std.fmt.bufPrint(path_buf, "{s}/{s}.txt", .{ outdir, label });
    return try fs_dir.createFile(name_slice, .{ .truncate = true });
}
