const std = @import("std");
const mem = std.mem;

const Direction = enum { left, right, up, down };

fn Forest(comptime size: usize) type {
    return struct {
        const ROW = size;
        const COLUMN = size;
        const VisMask = std.StaticBitSet(ROW * COLUMN);
        const Self = @This();
        input: [ROW][COLUMN]u8,
        width: u32,
        visible: VisMask,

        fn init(input: []const u8) Self {
            var lines = mem.tokenizeScalar(u8, input, '\n');
            const first_line = lines.next().?;
            const grid_width = first_line.len;

            var forest: Self = .{
                .input = @splat(@splat(0)),
                .visible = VisMask.initEmpty(),
                .width = @intCast(grid_width),
            };
            @memcpy(forest.input[0][0..], first_line);

            var row: usize = 1; // the first line have been copied already
            while (lines.next()) |line| : (row += 1) {
                @memcpy(forest.input[row][0..], line);
            }
            return forest;
        }

        fn isVisible(self: *const Self, x: usize, y: usize) bool {
            return !(x > 0 and y > 0 and x < self.width - 1 and y < self.width - 1);
        }

        pub fn scoreVisible(self: *Self, x: usize, y: usize, comptime direction: Direction) u64 {
            const tree = self.input[x][y];
            var row: usize = x;
            var column: usize = y;
            var score: u64 = 0;
            while (score < self.width) : (score += 1) {
                switch (direction) {
                    .left => row -= 1,
                    .right => row += 1,
                    .up => column -= 1,
                    .down => column += 1,
                }
                if (tree <= self.input[row][column]) break;
                if (self.isVisible(row, column)) {
                    std.debug.print("tree {c} = {}:x {}:y dir {s}\n", .{ tree, x, y, @tagName(direction) });
                    const column_offset = y * self.width;
                    self.visible.set(x + column_offset);
                    break;
                }
            }
            return score + 1;
        }
    };
}

fn solve(comptime input: []const u8) [2]u64 {
    const grid_width = comptime mem.indexOf(u8, input, "\n").?;

    var forest = Forest(grid_width).init(input);

    var part2: u64 = 0;

    var x: usize = 1;
    const dim = grid_width - 1;
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

    const sides_count = 4;
    // all outer trees are visible
    const visible_outer_grid = (sides_count * grid_width) - sides_count;
    const part1 = forest.visible.count() + visible_outer_grid;
    return .{ part1, part2 };
}

pub fn main() void {
    const sol = solve(@embedFile("data/day08.txt"));
    std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{ sol[0], sol[1] });
}

test "test-input" {
    const test_input =
        \\30373
        \\25512
        \\65332
        \\33549
        \\35390
    ;
    const sol = solve(test_input);
    std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{ sol[0], sol[1] });
}
