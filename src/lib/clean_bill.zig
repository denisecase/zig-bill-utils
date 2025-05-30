// src/lib/clean_bill.zig
const std = @import("std");

pub fn stripLineNumbers(line: []const u8) []const u8 {
    var i: usize = 0;
    while (i < line.len and std.ascii.isDigit(line[i])) : (i += 1) {}
    if (i < line.len and (line[i] == '.' or line[i] == ' ')) i += 1;
    return line[i..];
}
pub fn stripLineNumbersInPlace(line: []const u8, buf: *[4096]u8) []const u8 {
    var i: usize = 0;
    while (i < line.len and std.ascii.isDigit(line[i])) : (i += 1) {}
    if (i < line.len and (line[i] == '.' or line[i] == ' ')) i += 1;
    const len = @min(line.len - i, buf.len);
    std.mem.copy(u8, buf[0..len], line[i..i + len]);
    return buf[0..len];
}