const std = @import("std");
const fba = @import("alloc.zig");

const testing = std.testing;
const mem = std.mem;

const Set = std.AutoArrayHashMap(u8, void);

fn startpacket(datastream: []const u8, chunk_size: usize) usize {
    var win_iter = mem.window(u8, datastream, chunk_size, 1);
    var chunk_count: usize = 0;
    while (win_iter.next()) |chunk| : (chunk_count += 1) {
        var set = Set.init(fba.arena);
        set.ensureTotalCapacity(chunk_size) catch unreachable;
        defer set.deinit();

        for (chunk, 1..) |value, index| {
            const entry = set.getOrPutAssumeCapacity(value);
            if (entry.found_existing) {
                break;
            } else {
                if (index == chunk_size) {
                    return chunk_count + chunk_size;
                }
                entry.key_ptr.* = value;
            }
        }
    }
    unreachable;
}

test startpacket {
    {
        const marker_size = 4;
        const data = [_][]const u8{
            "mjqjpqmgbljsphdztnvjfqwrcgsmlb",
            "bvwbjplbgvbhsrlpgdmjqwftvncz",
            "nppdvjthqldpwncqszvftbrmjlhg",
            "nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg",
            "zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw",
        };
        for (data, 0..) |packet, index| {
            switch (index) {
                0 => try testing.expectEqual(startpacket(packet, marker_size), 7),
                1 => try testing.expectEqual(startpacket(packet, marker_size), 5),
                2 => try testing.expectEqual(startpacket(packet, marker_size), 6),
                3 => try testing.expectEqual(startpacket(packet, marker_size), 10),
                4 => try testing.expectEqual(startpacket(packet, marker_size), 11),
                else => unreachable,
            }
        }
    }
    {
        const marker_size = 14;
        const data = [_][]const u8{
            "mjqjpqmgbljsphdztnvjfqwrcgsmlb",
            "bvwbjplbgvbhsrlpgdmjqwftvncz",
            "nppdvjthqldpwncqszvftbrmjlhg",
            "nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg",
            "zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw",
        };
        for (data, 0..) |packet, index| {
            switch (index) {
                0 => try testing.expectEqual(startpacket(packet, marker_size), 19),
                1 => try testing.expectEqual(startpacket(packet, marker_size), 23),
                2 => try testing.expectEqual(startpacket(packet, marker_size), 23),
                3 => try testing.expectEqual(startpacket(packet, marker_size), 29),
                4 => try testing.expectEqual(startpacket(packet, marker_size), 26),
                else => unreachable,
            }
        }
    }
}

pub fn part1() usize {
    const input = @embedFile("data/day06.txt");
    const marker_size = 4;
    return startpacket(input, marker_size);
}

test part1 {
    try testing.expectEqual(part1(), 1987);
}

pub fn part2() usize {
    const input = @embedFile("data/day06.txt");
    const marker_size = 14;
    return startpacket(input, marker_size);
}

test part2 {
    try testing.expectEqual(part2(), 3059);
}
