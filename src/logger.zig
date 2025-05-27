// logger.zig - Shared logging functions for zig-bill-utils
// Must not overshadow reserved keywords like error or warn

const std = @import("std");

/// Logs the start of a tool run with a timestamp.
pub fn start(tool: []const u8) void {
    const now = std.time.timestamp();
    const writer = std.io.getStdErr().writer();
    _ = writer.print("[{s}] START at {d}\n", .{ tool, now }) catch {};
}

/// Logs the completion of a tool run with a timestamp.
pub fn done(tool: []const u8) void {
    const now = std.time.timestamp();
    const writer = std.io.getStdErr().writer();
    _ = writer.print("[{s}] DONE at {d}\n", .{ tool, now }) catch {};
}

/// Logs a regular step or informational message.
pub fn info(tool: []const u8, message: []const u8) void {
    const writer = std.io.getStdErr().writer();
    _ = writer.print("[{s}] {s}\n", .{ tool, message }) catch {};
}

/// Logs a warning message to stderr.
pub fn caution(tool: []const u8, message: []const u8) void {
    const writer = std.io.getStdErr().writer();
    _ = writer.print("[{s}] WARNING: {s}\n", .{ tool, message }) catch {};
}

/// Logs an error message to stderr.
pub fn fail(tool: []const u8, message: []const u8) void {
    const writer = std.io.getStdErr().writer();
    _ = writer.print("[{s}] ERROR: {s}\n", .{ tool, message }) catch {};
}
