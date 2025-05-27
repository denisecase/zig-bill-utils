// extract_money.zig - Extracts funding amounts from a bill text file

const std = @import("std");
const log = @import("logger.zig");
const utils = @import("utils.zig");

pub fn main() !void {
    const tool = "extract-money";
    log.start(tool);

    const allocator = std.heap.page_allocator;
    const args = try utils.parseArgs();

    if (utils.hasArg(args, "--help")) {
        try std.io.getStdOut().writer().writeAll(
            \\Usage: extract-money --path data/2025-hconres0014/clean.txt
            \\       extract-money --help
            \\
            \\Extracts funding amounts from a cleaned bill text file.
            \\Output format: CSV (amount,text)
            \\
            \\Output file: output/billname/money_lines.csv
            \\
        );
        return;
    }

    const input_path = try utils.requirePathArg(tool, args);
    const output_dir = try utils.resolveOutputDir(allocator, args, input_path);
    try std.fs.cwd().makePath(output_dir);

    const output_path = try utils.safeJoinPath(allocator, &.{ output_dir, "money_lines.csv" });
    const file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();
    const reader = file.reader();

    const out_file = try std.fs.cwd().createFile(output_path, .{ .truncate = true });
    defer out_file.close();
    const writer = out_file.writer();

    try writer.writeAll("amount,text\n");

    var buf: [4096]u8 = undefined;
    var line_num: usize = 0;
    var count: usize = 0;

    while (try utils.readLineTrimmed(reader, &buf)) |line| {
        line_num += 1;
        if (findMoney(line)) |amount| {
            try writer.print("\"{s}\",\"{s}\"\n", .{ amount, line });
            count += 1;
        }
    }

    log.info(tool, try std.fmt.allocPrint(allocator, "Found {d} matches", .{count}));
    log.done(tool);
}

fn findMoney(line: []const u8) ?[]const u8 {
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
