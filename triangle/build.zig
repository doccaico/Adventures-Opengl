const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "triangle",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    if (exe.root_module.optimize != .Debug) {
        exe.subsystem = .Windows;
    }

    b.exe_dir = switch (exe.root_module.optimize.?) {
        .Debug => b.pathJoin(&[_][]const u8{ b.install_path, "bin", "Debug" }),
        .ReleaseFast => b.pathJoin(&[_][]const u8{ b.install_path, "bin", "ReleaseFast" }),
        .ReleaseSafe => b.pathJoin(&[_][]const u8{ b.install_path, "bin", "ReleaseSafe" }),
        .ReleaseSmall => b.pathJoin(&[_][]const u8{ b.install_path, "bin", "ReleaseSmall" }),
    };

    // zglfw
    const zglfw = b.dependency("zglfw", .{});
    const zglfw_module = zglfw.module("root");
    zglfw_module.sanitize_c = .full;
    exe.root_module.addImport("zglfw", zglfw_module);
    exe.linkLibrary(zglfw.artifact("glfw"));

    // zopengl
    const zopengl = b.dependency("zopengl", .{});
    const zopengl_module = zopengl.module("root");
    exe.root_module.addImport("zopengl", zopengl_module);

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
