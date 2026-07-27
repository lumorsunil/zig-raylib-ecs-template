const std = @import("std");
const rlz = @import("raylib_zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const enable_ztracy = b.option(bool, "enable_ztracy", "Enable profiling with tracy.");

    const is_emscripten = target.query.os_tag == .emscripten;
    const opengl_version: rlz.OpenglVersion = if (is_emscripten) .gles_3 else .gl_3_3;

    const ztracy_dep = b.dependency("ztracy", .{
        .target = target,
        .optimize = optimize,
        .enable_ztracy = enable_ztracy,
    });
    const ztracy = ztracy_dep.module("root");
    const ztracy_artifact = ztracy_dep.artifact("tracy");

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
        .opengl_version = opengl_version,
    });
    const raylib = raylib_dep.module("raylib");
    const raylib_artifact = raylib_dep.artifact("raylib");

    const ecs = b.dependency("entt", .{
        .target = target,
        .optimize = optimize,
    }).module("zig-ecs");

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "ztracy", .module = ztracy },
            .{ .name = "raylib", .module = raylib },
            .{ .name = "ecs", .module = ecs },
        },
    });

    const run_step = b.step("run", "Run the app");

    if (is_emscripten) {
        const emsdk = rlz.emsdk;

        exe_mod.addCMacro("PLATFORM_WEB", "");
        exe_mod.addCMacro("GRAPHICS_API_OPENGL_ES_30", "");

        const wasm = b.addLibrary(.{
            .name = "wasm-out",
            .root_module = exe_mod,
        });

        const install_dir: std.Build.InstallDir = .{ .custom = "web" };
        const emcc_flags = emsdk.emccDefaultFlags(b.allocator, .{
            .optimize = optimize,
            .asyncify = true,
        });
        const emcc_settings = emsdk.emccDefaultSettings(b.allocator, .{
            .optimize = optimize,
            .es3 = true,
        });

        const emcc_step = emsdk.emccStep(b, raylib_artifact, wasm, .{
            .optimize = optimize,
            .flags = emcc_flags,
            .settings = emcc_settings,
            .install_dir = install_dir,
            .embed_paths = &.{.{ .src_path = "src/resources/" }},
        });
        b.getInstallStep().dependOn(emcc_step);

        const html_filename = try std.fmt.allocPrint(b.allocator, "{s}.html", .{wasm.name});

        const emrun_step = emsdk.emrunStep(
            b,
            b.getInstallPath(install_dir, html_filename),
            &.{},
        );

        emrun_step.dependOn(emcc_step);
        run_step.dependOn(emrun_step);
    } else {
        exe_mod.linkLibrary(ztracy_artifact);

        const exe = b.addExecutable(.{
            .name = "zig_raylib_ecs_template",
            .root_module = exe_mod,
        });

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_step.dependOn(&run_cmd.step);

        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
    }

    const exe_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);
}
