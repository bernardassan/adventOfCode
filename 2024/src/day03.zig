const std = @import("std");
const log = std.log;
const testing = std.testing;

pub fn part1() usize {
    const content = @embedFile("data/day03.txt");
    const content_lines_len = 300;

    var item_list = std.BoundedArray(u8, content_lines_len).init(0) catch unreachable;

    var lines = std.mem.tokenizeScalar(u8, content, '\n');

    while (lines.next()) |line| {
        const midpoint = @divExact(line.len, 2);
        const first_compartment = line[0..midpoint];
        const second_compartment = line[midpoint..];

        const common_item_in_compartments = first_compartment[std.mem.indexOfAny(u8, first_compartment, second_compartment).?];
        item_list.appendAssumeCapacity(common_item_in_compartments);
    }

    const priority_sum = itemsToPriority(item_list.constSlice());
    log.info(
        "The sum of the priorities of common items is {[priority_sum]}",
        .{ .priority_sum = priority_sum },
    );
    return priority_sum;
}

fn itemsToPriority(item_list: []const u8) usize {
    const map_lower_ascii = 96; //@as(u8, '`');
    const map_upper_ascii = 64; //@as(u8, '@');
    const alphabet_count = @as(u8, 26);

    var priority_sum: usize = 0;

    for (item_list) |value| {
        if (std.ascii.isLower(value)) {
            const value_priority = value - map_lower_ascii;
            priority_sum += value_priority;
        } else {
            const value_priority = value - map_upper_ascii + alphabet_count;
            priority_sum += value_priority;
        }
    }
    return priority_sum;
}

test part1 {
    try testing.expectEqual(@as(usize, 8139), part1());
}

pub fn part2() usize {
    const content = @embedFile("data/day03.txt");
    const content_lines_len = 100;

    var badge_list = std.BoundedArray(u8, content_lines_len).init(0) catch unreachable;

    var elves_groups = std.mem.tokenizeScalar(u8, content, '\n');
    var line_count: usize = 0;

    while (elves_groups.next()) |elf| : (line_count += 1) {
        const first_elf = elf;
        const second_elf = elves_groups.next().?;
        const third_elf = elves_groups.next().?;

        for (first_elf) |item| {
            if (std.mem.indexOfScalar(u8, second_elf, item)) |common_item_index|
                if (std.mem.indexOfScalar(u8, third_elf, second_elf[common_item_index])) |badge_item_index| {
                    badge_list.appendAssumeCapacity(third_elf[badge_item_index]);
                    //Beacuse the items in the elves compartments aren't unique you have to break after puting the first
                    //copy into `badge_list` else you would have duplicates badges which leds to wrong output
                    break;
                } else continue
            else
                continue;
        }
    }

    const priority_sum = itemsToPriority(badge_list.constSlice());
    log.info(
        "The sum of the priorities of badges in the various 3 elf group is {[priority_sum]}",
        .{ .priority_sum = priority_sum },
    );
    return priority_sum;
}
test part2 {
    try testing.expectEqual(@as(usize, 2668), part2());
}
