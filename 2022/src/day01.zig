const std = @import("std");
const log = std.log;
const testing = std.testing;
const env = @import("env");
const gpa = env.arena;

fn elveList() std.ArrayList(env.Calories) {
    const day01_txt = std.fs.cwd().openFile(
        "src/data/day01.txt",
        .{ .mode = .read_only },
    ) catch unreachable;
    defer day01_txt.close();

    var file_buf: [1024]u8 = undefined;
    var day01_data: std.fs.File.Reader = .init(day01_txt, &file_buf);
    var reader = &day01_data.interface;

    var elves_calories: std.ArrayList(env.Calories) = .empty;

    var current_total_calories: usize = 0;

    while (reader.takeDelimiterExclusive('\n')) |line| {
        if (line.len != env.EMPTY) {
            const elve_calories = std.fmt.parseInt(usize, line, 10) catch unreachable;
            current_total_calories += elve_calories;
        } else {
            //add the number of calories for the current elve
            elves_calories.append(gpa, current_total_calories) catch unreachable;
            //reset number of calories for next elve
            current_total_calories = 0;
        }
    } else |err| switch (err) {
        error.EndOfStream => {
            std.debug.assert(reader.seek == reader.end);
        },
        else => unreachable,
    }
    return elves_calories;
}

pub fn part1() usize {
    const elves_calories = elveList();
    const location_of_elve_with_max_calories = std.mem.indexOfMax(env.Calories, elves_calories.items);
    log.info(
        "The {[position]}th elve has the maximum number of calories which is {[max]}",
        .{ .position = location_of_elve_with_max_calories, .max = elves_calories.items[location_of_elve_with_max_calories] },
    );
    return elves_calories.items[location_of_elve_with_max_calories];
}

fn top3elves(list: []const usize) [3]usize {
    var top3: [3]usize = .{ 0, 0, 0 };
    for (list) |calories| {
        if (calories > top3[0]) {
            std.mem.swap(usize, &top3[1], &top3[2]);
            std.mem.swap(usize, &top3[0], &top3[1]);
            top3[0] = calories;
        } else if (calories > top3[1]) {
            std.mem.swap(usize, &top3[1], &top3[2]);
            top3[1] = calories;
        } else if (calories > top3[2]) {
            top3[2] = calories;
        }
    }
    return top3;
}

pub fn part2() usize {
    const elves_calories = elveList().items;
    // std.mem.sortUnstable(usize, elves_calories, {}, std.sort.desc(usize));
    const top_3_elves = top3elves(elves_calories);
    const total_calories_of_top_3_elves = sum: {
        var total: usize = 0;
        for (top_3_elves[0..3]) |calories| {
            total += calories;
        }
        break :sum total;
    };
    log.info(
        "The total calories of the top 3 elves is {[total]}",
        .{ .total = total_calories_of_top_3_elves },
    );
    return total_calories_of_top_3_elves;
}

test part2 {
    try testing.expectEqual(209481, part2());
}

test part1 {
    try testing.expectEqual(74711, part1());
}
