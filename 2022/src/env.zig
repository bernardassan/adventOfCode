const std = @import("std");
const builtin = @import("builtin");

pub const Calories = usize;
pub const EMPTY = 0;

var debug_alloc: std.heap.DebugAllocator(.{}) = .init;
pub const dbga = debug_alloc.allocator();

var buf: [1024 * 1024 * 32]u8 = undefined;
var fb_alloc: std.heap.FixedBufferAllocator = .init(&buf);
pub const fba = fb_alloc.allocator();

var arena_alloc: std.heap.ArenaAllocator = switch (builtin.mode) {
    .Debug => .init(dbga),
    else => .init(std.heap.smp_allocator),
};

pub const arena = arena_alloc.allocator();
