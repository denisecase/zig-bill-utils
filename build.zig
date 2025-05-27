const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const allocator = b.allocator;

    const tools = [_][]const u8{
        "clean_bill",
        "extract_amendments",
        "extract_headings",
        "extract_money",
        "filter_keywords",
        "split_sections"
    };

    for (tools) |tool| {
        const path_str = std.fmt.allocPrint(allocator, "src/{s}.zig", .{tool}) catch unreachable;

        const exe = b.addExecutable(.{
            .name = tool,
            .root_source_file = b.path(path_str),
            .target = target,
            .optimize = optimize,
        });

        b.installArtifact(exe);
    }
}
