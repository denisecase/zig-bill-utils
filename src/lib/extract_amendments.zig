// src/lib/extract_amendments.zig
const std = @import("std");


pub fn makeFilename(allocator: std.mem.Allocator, amendment_id: []const u8) ![]const u8 {
    var buf = try allocator.alloc(u8, amendment_id.len);
    var j: usize = 0;
    for (amendment_id) |c| {
        if (std.ascii.isAlphanumeric(c)) {
            buf[j] = std.ascii.toLower(c);
            j += 1;
        }
    }
    return try std.fmt.allocPrint(allocator, "sa{0s}.txt", .{buf[0..j]});
}
