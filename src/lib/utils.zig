// src/lib/utils.zig - Shared utilities

const std = @import("std");
const log = @import("logger.zig");

/// Returns a required `--path` argument or logs and fails.
pub fn requirePathArg(tool: []const u8, args: []const []const u8) ![]const u8 {
    const path = getArgValue(args, "--path") orelse {
        const msg = try std.fmt.allocPrint(std.heap.page_allocator, "Missing required --path argument.", .{});
        log.fail(tool, msg);
        return error.MissingArgument;
    };
    return path;
}

/// Returns an argument iterator using the page allocator.
pub fn getArgs() !std.process.ArgIterator {
    return std.process.ArgIterator.initWithAllocator(std.heap.page_allocator);
}

/// Parses command-line args into a slice using the page allocator.
pub fn parseArgs() ![]const []const u8 {
    var args = try getArgs();
    var list = std.ArrayList([]const u8).init(std.heap.page_allocator);

    while (args.next()) |arg| {
        try list.append(arg);
    }

    if (list.items.len < 1) {
        return error.MissingArgs;
    }

    return list.toOwnedSlice();
}

/// Checks if a specific flag (like "--help") exists in args.
pub fn hasArg(args: []const []const u8, target: []const u8) bool {
    for (args) |arg| {
        if (std.mem.eql(u8, arg, target)) return true;
    }
    return false;
}

/// Returns the value following a given key (e.g., "--path") from args.
/// Returns null if the key is not found or if there is no value after the key.
pub fn getArgValue(args: []const []const u8, key: []const u8) ?[]const u8 {
    var i: usize = 0;
    while (i + 1 < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], key)) {
            return args[i + 1];
        }
    }
    return null;
}



/// Resolves `--path` if present, otherwise returns a default path.
pub fn resolveInputPath(
    allocator: std.mem.Allocator,
    args: []const []const u8,
    default_path: []const u8,
) ![]u8 {
    if (getArgValue(args, "--path")) |val| {
        return allocator.dupe(u8, val);
    }
    return allocator.dupe(u8, default_path);
}

/// Builds a relative path like "data/bill-name/filename".
pub fn joinBillFilePath(
    allocator: std.mem.Allocator,
    bill_name: []const u8,
    filename: []const u8,
) ![]u8 {
    return std.fs.path.join(allocator, &.{ "data", bill_name, filename });
}

/// Joins multiple path parts safely using the allocator.
pub fn safeJoinPath(
    allocator: std.mem.Allocator,
    parts: []const []const u8,
) ![]u8 {
    return std.fs.path.join(allocator, parts);
}

/// Returns the contents of a line trimmed of whitespace and newline chars.
pub fn readLineTrimmed(reader: anytype, buf: *[4096]u8) !?[]const u8 {
    const line = try reader.readUntilDelimiterOrEof(buf, '\n');
    return if (line) |l| std.mem.trim(u8, l, " \r\n") else null;
}

/// Returns a lowercase-allocated copy of the input.
pub fn toLowerAlloc(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    var buf = try allocator.alloc(u8, input.len);
    for (input, 0..) |c, i| {
        buf[i] = std.ascii.toLower(c);
    }
    return buf;
}

/// Converts input to lowercase in the given buffer and returns a slice.
pub fn toLowerInPlace(input: []const u8, buf: *[4096]u8) []const u8 {
    const len = @min(input.len, buf.len);
    var i: usize = 0;
    while (i < len) : (i += 1) {
        buf[i] = std.ascii.toLower(input[i]);
    }
    return buf[0..len];
}

/// Returns true if the text contains any of the provided keywords.
pub fn containsAny(text: []const u8, keywords: []const []const u8) bool {
    for (keywords) |kw| {
        if (std.mem.indexOf(u8, text, kw)) |_| return true;
    }
    return false;
}

/// Reads a list of terms from a file, one per line.
/// - Ignores blank lines and `#` comments.
/// - Strips surrounding quotes from quoted phrases.
/// - Returns a list of heap-allocated slices.
pub fn readTermsFromFile(
    allocator: std.mem.Allocator,
    path: []const u8,
) ![][]const u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    const reader = file.reader();

    var buf: [4096]u8 = undefined;
    var terms = std.ArrayList([]const u8).init(allocator);

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r\n");

        if (trimmed.len == 0 or std.mem.startsWith(u8, trimmed, "#")) {
            continue;
        }

        const term = if (trimmed[0] == '"' and trimmed[trimmed.len - 1] == '"')
            trimmed[1 .. trimmed.len - 1]
        else
            trimmed;

        try terms.append(try allocator.dupe(u8, term));
    }

    return terms.toOwnedSlice();
}

/// Resolves output directory: uses --outdir or defaults to output/<billname>
pub fn resolveOutputDir(
    allocator: std.mem.Allocator,
    args: []const []const u8,
    input_path: []const u8,
) ![]u8 {
    if (getArgValue(args, "--outdir")) |val| {
        return allocator.dupe(u8, val);
    }
    if (std.fs.path.dirname(input_path)) |folder| {
        const billname = std.fs.path.basename(folder); // e.g. "2025-hconres0014"
        return std.fs.path.join(allocator, &.{ "output", billname });
    }
    return error.CouldNotDetermineOutputFolder;
}

/// Converts an "output/" path to a "data/" path.
pub fn convertOutputToDataPath(allocator: std.mem.Allocator, path: []const u8) ![]const u8 {
    if (std.mem.startsWith(u8, path, "output/")) {
        return try std.fmt.allocPrint(allocator, "data/{s}", .{path["output/".len..]});
    } else {
        return allocator.dupe(u8, path);
    }
}

