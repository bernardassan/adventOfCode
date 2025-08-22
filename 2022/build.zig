const std = @import("std");

const max_aoc_per_year = 25; // AOC ends after 25th December

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const env = b.createModule(.{ .root_source_file = b.path("src/env.zig") });

    const all_step = b.step("2024", "Run all AOC 2024");
    const src = "src/";
    const files = try findFiles(b, src);
    for (files) |basename| {
        const name = basename[0.."day..".len];

        const exe = b.addTest(.{
            .name = name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(b.fmt(
                    "{[path]s}/{[basename]s}",
                    .{ .path = src, .basename = basename },
                )),
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "env", .module = env },
                },
            }),
        });
        const run_step = b.step(name, b.fmt("Run {s}", .{name}));

        const run_cmd = b.addRunArtifact(exe);
        run_step.dependOn(&run_cmd.step);
        all_step.dependOn(run_step);

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
    }
}

fn findFiles(b: *std.Build, src: []const u8) ![]const []const u8 {
    var dir = try b.build_root.handle.openDir(src, .{ .iterate = true });
    defer dir.close();

    var walker = try dir.walk(b.allocator);
    defer walker.deinit();

    var sources: std.ArrayList([]const u8) = .empty;
    try sources.ensureTotalCapacityPrecise(b.allocator, max_aoc_per_year);

    while (try walker.next()) |entry| {
        if (entry.kind == .file and std.mem.eql(u8, entry.basename[0..3], "day")) {
            sources.appendAssumeCapacity(b.dupe(entry.basename));
        }
    }

    std.mem.sortUnstable([]const u8, sources.items, {}, struct {
        pub fn lessThanFn(context: void, lhs: []const u8, rhs: []const u8) bool {
            _ = context;
            return std.mem.lessThan(u8, lhs, rhs);
        }
    }.lessThanFn);

    return sources.items;
}
