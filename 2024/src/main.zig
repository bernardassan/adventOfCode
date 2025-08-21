const std = @import("std");
const day01 = @import("day01.zig");
const day02 = @import("day02.zig");
const day03 = @import("day03.zig");
const day04 = @import("day04.zig");
const day05 = @import("day05.zig");
const day06 = @import("day06.zig");
const day07 = @import("day07.zig");
const day08 = @import("day08.zig");

pub const std_options: std.Options = .{ .log_level = .info };

pub fn main() !void {
    _ = day01.part1();
    _ = day01.part2();
    _ = day02.part1();
    _ = day02.part2();
    _ = day03.part1();
    _ = day03.part2();
    _ = day04.part1();
    _ = day04.part2();
    _ = day05.part1();
    _ = day05.part2();
    _ = day06.part1();
    _ = day06.part2();
    _ = day07.part1();
    _ = day07.part2();
    _ = day08.main();
}

test {
    _ = day01;
    _ = day02;
    _ = day03;
    _ = day04;
    _ = day05;
    _ = day06;
    _ = day07;
}
