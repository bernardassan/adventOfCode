const std = @import("std");
const mem = std.mem;

const Size = 100;
const VisMask = std.StaticBitSet(Size);
const Column = 100;
const Row = 100;
const Direction = enum { left, right, up, down };

const Forest = struct {
    const Self = @This();
    input: [Row][Column]u8,
    width: u32,
    visible: VisMask,

    fn init(input: []const u8) Forest {
        var lines = mem.tokenizeScalar(u8, input, '\n');
        const first_line = lines.next().?;

        const forest: Forest = .{ .input = @splat(0), .visible = VisMask.initEmpty(), .width = first_line.len };
        @memcpy(forest.input[0], first_line);

        var row: usize = 0;
        while (lines.next()) |line| : (row += 1) {
            @memcpy(forest.input[row], line);
        }
        return forest;
    }

    fn nextInbounds(self: *const Self, x: usize, y: usize) bool {
        return x > 0 and y > 0 and y < self.size - 1 and x < self.size - 1;
    }

    pub fn scoreVisible(self: *Self, x: usize, y: usize, comptime direction: Direction) u64 {
        const tree = self.input[y][x];
        var i: usize = x;
        var j: usize = y;
        var score: u64 = 0;
        while (score < self.size) : (score += 1) {
            switch (direction) {
                .left => i -= 1,
                .right => i += 1,
                .up => j -= 1,
                .down => j += 1,
            }
            if (tree <= self.input[j][i]) break;
            if (!self.nextInbounds(i, j)) {
                self.visible.set(x + y * self.size);
                break;
            }
        }
        return score + 1;
    }
};

fn solve(input: []const u8) [2]u64 {
    const size = std.mem.indexOf(u8, input, "\n").?;

    var visible = try VisMask.initEmpty(size * size);

    const forest = Forest.init(input);

    var part2: u64 = 0;

    var x: usize = 1;
    const dim = size - 1;
    while (x < dim) : (x += 1) {
        var y: usize = 1;
        while (y < dim) : (y += 1) {
            var total: u64 = 1;
            inline for ([_]Direction{ .up, .down, .left, .right }) |dir| {
                const score = forest.scoreVisible(x, y, dir);
                total *= score;
            }
            part2 = @max(total, part2);
        }
    }

    const part1 = visible.count() + (4 * size) - 4;
    return .{ part1, part2 };
}

pub fn main() !void {
    const sol = try solve(@embedFile("input.txt"));
    std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{ sol[0], sol[1] });
}

test "test-input" {
    const sol = try solve(std.testing.allocator, @embedFile("test.txt"));
    std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{ sol[0], sol[1] });
}
