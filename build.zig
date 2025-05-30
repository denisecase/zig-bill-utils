const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const allocator = b.allocator;

    const arch = @tagName(target.query.cpu_arch orelse unreachable);
    const os = @tagName(target.query.os_tag orelse unreachable);

    const out_subdir = std.fmt.allocPrint(allocator, "{s}-{s}", .{ arch, os }) catch unreachable;

    // Create the shared lib module
    const lib = b.createModule(.{
        .root_source_file = b.path("src/lib/lib.zig"),
    });

    // Define tool names and variants
    const tools = [_][]const u8{
        "clean_bill",
        "extract_amendments",
        "extract_headings",
        "extract_money",
        "filter_keywords",
        "split_sections",
    };

    const variants = [_][]const u8{
        "file",
        "stream",
    };

    // Loop over tools and variants to build each executable
    for (variants) |variant| {
        for (tools) |tool| {
            const exe_name = std.fmt.allocPrint(allocator, "{s}_{s}", .{ tool, variant }) catch unreachable;
            const src_path = std.fmt.allocPrint(allocator, "src/{s}/{s}.zig", .{ variant, tool }) catch unreachable;

            const exe = b.addExecutable(.{
                .name = exe_name,
                .root_source_file = b.path(src_path),
                .target = target,
                .optimize = optimize,
            });

            // Add the lib module to each executable
            exe.root_module.addImport("lib", lib);

            // Install the executable
            const install_step = b.addInstallArtifact(exe, .{
                .dest_dir = .{ .override = .{ .custom = out_subdir } },
            });

            // Ensure install step depends on this tool
            b.getInstallStep().dependOn(&install_step.step);
        }
    }
}
