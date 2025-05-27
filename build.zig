// build.zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const allocator = b.allocator;

    const arch = @tagName(target.query.cpu_arch orelse unreachable);
    const os   = @tagName(target.query.os_tag orelse unreachable);

    const tools = [_][]const u8{
        "clean_bill",
        "extract_amendments",
        "extract_headings",
        "extract_money",
        "filter_keywords",
        "split_sections",
    };

    const out_subdir = std.fmt.allocPrint(allocator, "{s}-{s}", .{ arch, os }) catch unreachable;

    for (tools) |name| {
        const src_path = std.fmt.allocPrint(allocator, "src/{s}.zig", .{name}) catch unreachable;

        const exe = b.addExecutable(.{
            .name = name,
            .root_source_file = b.path(src_path),
            .target = target,
            .optimize = optimize,
        });

        const install_step = b.addInstallArtifact(exe, .{
            .dest_dir = .{ .override = .{ .custom = out_subdir } },
        });

        b.getInstallStep().dependOn(&install_step.step);
    }

}
