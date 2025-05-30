// src/lib/extract_money.zig
const std = @import("std");

pub fn findMoney(line: []const u8) ?[]const u8 {
    var i: usize = 0;
    while (i < line.len) : (i += 1) {
        if (line[i] == '$') {
            var j = i + 1;
            while (j < line.len and
                (std.ascii.isDigit(line[j]) or
                 line[j] == ',' or
                 line[j] == '.' or
                 std.ascii.isAlphabetic(line[j]) or
                 line[j] == ' ')) : (j += 1)
            {}
            return line[i..j];
        }
    }
    return null;
}
