const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "aoc2022",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    //zls check step to if all aoc days compile
    const check = b.step("check", "ensure that all AOC days compile without errors");
    const check_day = b.addExecutable(.{
        .name = "check_aoc",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = .Debug,
        .use_llvm = false,
        .use_lld = false,
    });
    check.dependOn(&check_day.step);

    //TODO: maybe switch to per file executables for AOC
    // {
    //     const sub_path = "src";
    //     const path = try std.fs.Dir.openDir(std.fs.cwd(), sub_path, .{ .iterate = true });
    //     var iter = path.iterate();
    //     while (try iter.next()) |file| {
    //         switch (file.kind) {
    //             .file => {
    //                 std.log.debug("{s}\n", .{file.name});
    //                 const check_day = b.addExecutable(.{
    //                     .name = file.name,
    //                     .root_source_file = b.path(b.fmt("{[sub_path]s}/{[file_name]s}", .{
    //                         .sub_path = sub_path,
    //                         .file_name = file.name,
    //                     })),
    //                     .target = target,
    //                     .optimize = .Debug,
    //                     .use_llvm = false,
    //                     .use_lld = false,
    //                 });
    //                 const run_check_day = b.addRunArtifact(check_day);
    //                 check.dependOn(&run_check_day.step);
    //             },
    //             else => continue,
    //         }
    //     }
    // }
}
