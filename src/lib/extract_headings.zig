// src/lib/extract_headings.zig
const std = @import("std");

pub fn isHeading(line: []const u8) bool {
    return std.mem.startsWith(u8, line, "title ") or
        std.mem.startsWith(u8, line, "sec.") or
        std.mem.startsWith(u8, line, "section ");
}
