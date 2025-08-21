const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;
const log = std.log;
const testing = std.testing;

pub fn part1() usize {
    const content = @embedFile("data/day04.txt");

    var elf_pair = mem.tokenizeScalar(u8, content, '\n');

    var number_of_fully_contained_pairs: usize = 0;

    while (elf_pair.next()) |elves| {
        var elves_section_range = mem.tokenizeScalar(u8, elves, ',');
        const first_range = elves_section_range.next().?;
        const second_range = elves_section_range.next().?;

        var first_range_numbers = mem.splitScalar(u8, first_range, '-');
        const first_range_start = fmt.parseUnsigned(usize, first_range_numbers.next().?, 10) catch unreachable;
        const first_range_end = fmt.parseUnsigned(usize, first_range_numbers.next().?, 10) catch unreachable;

        var second_range_numbers = mem.splitScalar(u8, second_range, '-');
        const second_range_start = fmt.parseUnsigned(usize, second_range_numbers.next().?, 10) catch unreachable;
        const second_range_end = fmt.parseUnsigned(usize, second_range_numbers.next().?, 10) catch unreachable;

        //check if range overlap fully
        if (first_range_start <= second_range_start and first_range_end >= second_range_end) {
            number_of_fully_contained_pairs += 1;
        } else if (second_range_start <= first_range_start and second_range_end >= first_range_end) {
            number_of_fully_contained_pairs += 1;
        }
    }

    log.info("{} assignment pairs are fully contain by other section assignment ranges", .{number_of_fully_contained_pairs});

    return number_of_fully_contained_pairs;
}

test part1 {
    try testing.expectEqual(@as(usize, 573), part1());
}

pub fn part2() usize {
    const content = @embedFile("data/day04.txt");

    var elf_pair = mem.tokenizeScalar(u8, content, '\n');

    var number_of_overlapping_pairs: usize = 0;

    while (elf_pair.next()) |elves| {
        var elves_section_range = mem.tokenizeScalar(u8, elves, ',');
        const first_range = elves_section_range.next().?;
        const second_range = elves_section_range.next().?;

        var first_range_numbers = mem.splitScalar(u8, first_range, '-');
        const first_range_start = fmt.parseUnsigned(usize, first_range_numbers.next().?, 10) catch unreachable;
        const first_range_end = fmt.parseUnsigned(usize, first_range_numbers.next().?, 10) catch unreachable;

        var second_range_numbers = mem.splitScalar(u8, second_range, '-');
        const second_range_start = fmt.parseUnsigned(usize, second_range_numbers.next().?, 10) catch unreachable;
        const second_range_end = fmt.parseUnsigned(usize, second_range_numbers.next().?, 10) catch unreachable;

        //check if range overlap at all
        if (first_range_start <= second_range_start and first_range_end >= second_range_start) {
            number_of_overlapping_pairs += 1;
        } else if (second_range_start <= first_range_start and second_range_end >= first_range_start) {
            number_of_overlapping_pairs += 1;
        }
    }

    log.info("{} assignment pairs overlap with their consecutive section assignments", .{number_of_overlapping_pairs});

    return number_of_overlapping_pairs;
}

test part2 {
    try testing.expectEqual(@as(usize, 867), part2());
}
