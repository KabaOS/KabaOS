const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "eepshare",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
        .strip = optimize == std.builtin.Mode.ReleaseFast,
    });

    exe.linkLibC();
    exe.addCSourceFile(.{ .file = .{ .path = "libsam3/src/libsam3/libsam3.c" }, .flags = &.{} });
    exe.addIncludePath(.{ .path = "libsam3/src/libsam3" });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
