const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const fmt = std.fmt;
const debug = std.debug;
const alloc = @import("alloc.zig");

const Fs = struct {
    root: Directory,
    arena: mem.Allocator,

    const File = struct {
        name: []const u8,
        size: usize,
    };

    const Directory = struct {
        name: []const u8,
        files: std.ArrayListUnmanaged(File),
        sub_dirs: std.ArrayListUnmanaged(Directory),
        parent: ?*Directory,
        size: usize,

        fn init(name: []const u8, parent: ?*Directory) Directory {
            return .{
                .name = name,
                .files = .{},
                .sub_dirs = .{},
                .parent = parent,
                .size = 0,
            };
        }

        fn deinit(dir: *Directory, arena: mem.Allocator) void {
            dir.files.deinit(arena);
            dir.sub_dirs.deinit(arena);
            if (dir.parent) |parent| {
                parent.deinit(arena);
            }
        }
    };

    fn init(arena: mem.Allocator) Fs {
        return .{
            .root = .init("/", null),
            .arena = arena,
        };
    }

    fn deinit(fs: *Fs, dir: *Directory) void {
        dir.deinit(fs.arena);
    }

    fn browseFs(fs: *Fs, actions: []const u8) *Directory {
        const arena = fs.arena;
        const root = &fs.root;
        var current_dir = root;

        var command_output = mem.tokenizeAny(u8, actions, "$");
        while (command_output.next()) |commands| {
            var command = mem.tokenizeAny(u8, commands, " \n");
            while (command.next()) |next_command| {
                if (mem.eql(u8, next_command, "cd")) {
                    const cd_dir_name = command.next().?;
                    if (mem.eql(u8, cd_dir_name, "/")) {
                        continue;
                    } else if (mem.eql(u8, cd_dir_name, "..")) {
                        current_dir = current_dir.parent.?;
                    } else {
                        for (current_dir.sub_dirs.items) |*dir| {
                            if (mem.eql(u8, dir.name, cd_dir_name)) {
                                current_dir = dir;
                                break;
                            }
                        } else {
                            unreachable;
                        }
                    }
                } else {
                    debug.assert(mem.eql(u8, next_command, "ls"));

                    while (command.next()) |dir_or_filesize| {
                        if (mem.eql(u8, dir_or_filesize, "dir")) {
                            const sub_dir_name = command.next().?;
                            const sub_dir: Directory = .init(
                                sub_dir_name,
                                current_dir,
                            );
                            current_dir.sub_dirs.append(
                                arena,
                                sub_dir,
                            ) catch unreachable;
                        } else {
                            const file_name = command.next().?;
                            const file_size = fmt.parseUnsigned(
                                usize,
                                dir_or_filesize,
                                10,
                            ) catch unreachable;

                            current_dir.size += file_size;

                            var next_parent = current_dir.parent;
                            while (next_parent) |parent| : ({
                                next_parent = parent.parent;
                            }) {
                                parent.size += file_size;
                            }

                            current_dir.files.append(arena, File{
                                .name = file_name,
                                .size = file_size,
                            }) catch unreachable;
                        }
                    }
                }
            }
        }
        return root;
    }

    const fs_operations =
        \\$ cd /
        \\$ ls
        \\dir a
        \\14848514 b.txt
        \\8504156 c.dat
        \\dir d
        \\$ cd a
        \\$ ls
        \\dir e
        \\29116 f
        \\2557 g
        \\62596 h.lst
        \\$ cd e
        \\$ ls
        \\584 i
        \\$ cd ..
        \\$ cd ..
        \\$ cd d
        \\$ ls
        \\4060174 j
        \\8033020 d.log
        \\5626152 d.ext
        \\7214296 k
    ;

    test browseFs {
        var arena = std.heap.ArenaAllocator.init(testing.allocator);
        defer arena.deinit();

        var device_fs = Fs.init(arena.allocator());
        const dir = device_fs.browseFs(fs_operations);
        defer device_fs.deinit(dir);

        try testing.expectEqual(48381165, dir.size);

        const files = dir.files.items;
        const sub_dirs = dir.sub_dirs.items;
        for (0..2) |max_depth| {
            switch (max_depth) {
                0 => {
                    const file_b = Fs.File{
                        .name = "b.txt",
                        .size = 14848514,
                    };
                    try testing.expectEqualDeep(file_b, files[max_depth]);
                    const dir_a = sub_dirs[max_depth];
                    try testing.expectEqualSlices(u8, dir_a.name, "a");
                    try testing.expectEqual(94853, dir_a.size);
                    try testing.expectEqual(dir_a.parent.?.name, "/");
                    const dir_e = sub_dirs[max_depth].sub_dirs.items[max_depth];
                    try testing.expectEqual(584, dir_e.size);

                    const i_file_index = 0;
                    const file_i_actual = dir_e.files.items[i_file_index];
                    const file_i = Fs.File{
                        .name = "i",
                        .size = 584,
                    };

                    try testing.expectEqualDeep(file_i, file_i_actual);
                },
                1 => {
                    const file_c = Fs.File{
                        .name = "c.dat",
                        .size = 8504156,
                    };
                    try testing.expectEqualDeep(file_c, files[max_depth]);
                    const dir_d = sub_dirs[max_depth];
                    try testing.expectEqualSlices(u8, dir_d.name, "d");
                    try testing.expectEqual(24933642, dir_d.size);

                    try testing.expectEqual(dir_d.parent.?.name, "/");
                    const k_file_index = 3;
                    const file_k_actual = sub_dirs[max_depth].files.items[k_file_index];
                    const file_k = Fs.File{
                        .name = "k",
                        .size = 7214296,
                    };

                    try testing.expectEqualDeep(file_k, file_k_actual);
                },
                else => unreachable,
            }
        }
    }

    /// sum the sizes of directories which are <= `max_size`
    /// using preorder traversal of the directory tree
    fn sumSizeOfDir(fs: *Fs, max_size: usize) usize {
        var running_sum: usize = if (fs.root.size <= max_size) fs.root.size else 0;
        var stack: std.ArrayList([]Directory) = .init(fs.arena);
        stack.append(fs.root.sub_dirs.items) catch unreachable;
        while (stack.popOrNull()) |dirs| {
            for (dirs) |dir| {
                if (dir.size <= max_size) running_sum += dir.size;
                if (dir.sub_dirs.items.len != 0) {
                    stack.append(dir.sub_dirs.items) catch unreachable;
                }
            }
        }
        return running_sum;
    }

    test sumSizeOfDir {
        var arena = std.heap.ArenaAllocator.init(testing.allocator);
        defer arena.deinit();

        var device_fs = Fs.init(arena.allocator());
        const dir = device_fs.browseFs(fs_operations);
        defer device_fs.deinit(dir);

        try testing.expectEqual(95437, device_fs.sumSizeOfDir(100_000));
    }

    fn dirToDelToEnableUpdate(fs: *Fs) struct { []const u8, usize } {
        const total_disk_space = 70000000;
        const needed_unused_space = 30000000;

        const total_used_space = fs.root.size;
        const current_unused_space = total_disk_space - total_used_space;
        // we need to delete a directory which is >= this size but less than
        // the `total_used_space`
        const size_of_extra_space_needed = needed_unused_space - current_unused_space;

        var smallest_big_dir: struct { []const u8, usize } = .{ "", total_used_space };
        var stack: std.ArrayList([]Directory) = .init(fs.arena);
        stack.append(fs.root.sub_dirs.items) catch unreachable;
        while (stack.popOrNull()) |dirs| {
            for (dirs) |dir| {
                if (dir.size >= size_of_extra_space_needed) smallest_big_dir = .{ dir.name, @min(dir.size, smallest_big_dir[1]) };
                if (dir.sub_dirs.items.len != 0) {
                    stack.append(dir.sub_dirs.items) catch unreachable;
                }
            }
        }
        return smallest_big_dir;
    }

    test dirToDelToEnableUpdate {
        var arena = std.heap.ArenaAllocator.init(testing.allocator);
        defer arena.deinit();

        var device_fs = Fs.init(arena.allocator());
        const dir = device_fs.browseFs(fs_operations);
        defer device_fs.deinit(dir);

        try testing.expectEqualDeep(.{ "d", 24_933_642 }, device_fs.dirToDelToEnableUpdate());
    }

    fn printTree(fs: *Fs) void {
        std.debug.print("root: {s} - size: {}\n", .{ fs.root.name, fs.root.size });
        for (fs.root.files.items) |file| {
            std.debug.print("file: {s} - size: {}\n", .{ file.name, file.size });
        }
        var stack: std.ArrayList([]Directory) = .init(fs.arena);
        stack.append(fs.root.sub_dirs.items) catch unreachable;
        while (stack.popOrNull()) |dirs| {
            for (dirs) |dir| {
                std.debug.print("dir: {s} - size: {}\n", .{ dir.name, dir.size });
                for (dir.files.items) |file| {
                    std.debug.print("file: {s} - size: {}\n", .{ file.name, file.size });
                }
                if (dir.sub_dirs.items.len != 0) {
                    stack.append(dir.sub_dirs.items) catch unreachable;
                }
            }
        }
    }

    test printTree {
        if (true)
            return error.SkipZigTest;

        var arena = std.heap.ArenaAllocator.init(testing.allocator);
        defer arena.deinit();

        var device_fs = Fs.init(arena.allocator());
        const dir = device_fs.browseFs(fs_operations);
        defer device_fs.deinit(dir);

        device_fs.printTree();
    }
};

pub fn part1() usize {
    const data = @embedFile("data/day07.txt");

    var device_fs = Fs.init(alloc.arena);
    const dir = device_fs.browseFs(data);
    defer device_fs.deinit(dir);

    return device_fs.sumSizeOfDir(100_000);
}

test part1 {
    try testing.expectEqual(1_432_936, part1());
}

pub fn part2() struct { []const u8, usize } {
    const data = @embedFile("data/day07.txt");

    var device_fs = Fs.init(alloc.arena);
    const dir = device_fs.browseFs(data);
    defer device_fs.deinit(dir);

    return device_fs.dirToDelToEnableUpdate();
}

test part2 {
    try testing.expectEqualDeep(.{ "jfzgrbm", 272_298 }, part2());
}

test {
    _ = Fs;
}
