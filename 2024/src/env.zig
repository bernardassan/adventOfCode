const std = @import("std");
const builtin = @import("builtin");

pub const std_options: std.Options = .{ .log_level = .info };

pub const Calories = usize;
pub const EMPTY = 0;
pub const DATA_DIR = "../data/";

var debug_alloc = std.heap.DebugAllocator(.{}){};
pub const dbga = debug_alloc.allocator();

var arena_alloc = switch (builtin.mode) {
    .Debug => std.heap.ArenaAllocator.init(dbga),
    else => std.heap.ArenaAllocator.init(std.heap.smp_allocator),
};

pub const arena = arena_alloc.allocator();
