const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zap = b.dependency("zap", .{
        .target = target,
        .optimize = optimize,
        .openssl = true,
    });
    const jwt = b.dependency("jwt", .{
        .target = target,
        .optimize = optimize,
    });

    const core_mod = b.createModule(.{
        .root_source_file = b.path("src/Core/core.zig"),
        .target = target,
        .optimize = optimize,
    });
    core_mod.addImport("zap", zap.module("zap"));
    core_mod.addImport("jwt", jwt.module("jwt"));

    const mf_exe_mod = b.createModule(.{
        .root_source_file = b.path("src/MainFrame/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    mf_exe_mod.addImport("core", core_mod);
    mf_exe_mod.addImport("zap", zap.module("zap"));
    mf_exe_mod.addImport("jwt", jwt.module("jwt"));

    const mf_exe = b.addExecutable(.{
        .name = "MainFrame",
        .root_module = mf_exe_mod,
    });
    b.installArtifact(mf_exe);

    const run_cmd = b.addRunArtifact(mf_exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run_mf", "Run the MainFrame");
    run_step.dependOn(&run_cmd.step);

    const mf_exe_unit_tests = b.addTest(.{
        .root_module = mf_exe_mod,
    });
    const run_mf_exe_unit_tests = b.addRunArtifact(mf_exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_mf_exe_unit_tests.step);
}
