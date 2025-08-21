const std = @import("std");
const builtin = @import("builtin");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

var buf: [1024 * 1024 * 32]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&buf);

var arena_alloc = switch (builtin.mode) {
    .Debug => std.heap.ArenaAllocator.init(fba.allocator()),
    else => std.heap.ArenaAllocator.init(gpa.allocator()),
};

pub const arena = arena_alloc.allocator();
