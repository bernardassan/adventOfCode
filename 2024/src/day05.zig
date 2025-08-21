const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const log = std.log;
const io = std.io;

const StacksOfCrates = struct {
    const Self = @This();

    const stack_offset = 4;
    const column_no = 9;
    const column_len = 8;
    const column_upper_bound = column_len + 40; //the +40 is to account for the lenght during crates shuffle/movement
    const moves_no = 501;

    const Stack = std.BoundedArray(u8, column_upper_bound);

    /// struct { quantity: u9, from: u9, to: u9 };
    const Move = struct { u9, u9, u9 };

    const Moves = [moves_no]Move;
    const Crates = [column_no]Stack;

    crates: Crates,
    moves: Moves,

    pub fn init() Self {
        const input = @embedFile("data/day05.txt");
        var crates: [column_no]Stack = [_]Stack{Stack.init(0) catch unreachable} ** column_no;

        var lines = mem.splitScalar(u8, input, '\n');
        while (lines.next()) |line| {
            //end of the stack
            if (line[0] != '[') {
                _ = lines.next(); //skip the column numbers under the stack
                break;
            }
            var stack_index: usize = 0;
            while (stack_index < column_no) : (stack_index += 1) {
                const position = (stack_offset * stack_index) + 1; // +1 due to 0 counting
                const stack_value = line[position];

                if (stack_value != ' ')
                    crates[stack_index].appendAssumeCapacity(stack_value);
            }
        }

        var moves: Moves = undefined;

        var instruction_index: usize = 0;
        while (lines.next()) |instructions| : (instruction_index += 1) {
            if (instructions.len == 0) break;

            var instruction = mem.tokenizeAny(u8, instructions, "move from to");
            moves[instruction_index] = Move{
                parse(instruction.next().?),
                parse(instruction.next().?),
                parse(instruction.next().?),
            };
        }

        // reverse the stack so that its end match the input sample end
        for (&crates) |*stack| {
            mem.reverse(u8, stack.slice());
        }

        return .{ .crates = crates, .moves = moves };
    }

    fn parse(buf: []const u8) u9 {
        return std.fmt.parseUnsigned(u9, buf, 10) catch unreachable;
    }

    fn print(self: *const Self) void {
        const stdout_file = io.getStdOut().writer();
        var bw = io.bufferedWriter(stdout_file);
        const stdout = bw.writer();

        for (self.crates, 0..) |row, index| {
            stdout.print("{}", .{index});
            for (row.constSlice()) |value| {
                stdout.print("[{c}]", .{value}) catch unreachable;
            }
            stdout.print("\n", .{}) catch unreachable;
        }
        bw.flush() catch unreachable;
    }

    ///get top of stacks
    fn top(self: *const Self) [9]u8 {
        var buf: [9]u8 = undefined;
        var fbs = io.fixedBufferStream(&buf);
        var bw = io.bufferedWriter(fbs.writer());
        defer bw.flush() catch unreachable;

        const output = bw.writer();

        for (self.crates) |crate| {
            if (crate.len > 0) output.print(
                "{c}",
                .{crate.get(crate.len - 1)},
            ) catch unreachable;
        }

        return mem.bytesToValue([9]u8, bw.buf[0..bw.end]);
    }
};

pub fn part1() [9]u8 {
    var stacks = StacksOfCrates.init();

    for (stacks.moves) |instruction| {
        const quantity, const from, const to = instruction;

        var move_count: usize = 0;
        while (move_count < quantity) : (move_count += 1) {
            const move_value = stacks.crates[from - 1].pop();
            stacks.crates[to - 1].appendAssumeCapacity(move_value);
        }
    }
    const top = stacks.top();
    //get top of stacks
    log.info("{s}", .{top});
    return top;
}

test part1 {
    try testing.expectEqual(
        [9]u8{ 'P', 'T', 'W', 'L', 'T', 'D', 'S', 'J', 'V' },
        part1(),
    );
}

pub fn part2() [9]u8 {
    var stacks = StacksOfCrates.init();

    for (stacks.moves) |instructions| {
        const quantity, const from, const to = instructions;

        var move_crate = StacksOfCrates.Stack.init(0) catch unreachable;

        var move_from_count: usize = 0;
        //move count crates into the `move_crate`
        while (move_from_count < quantity) : (move_from_count += 1) {
            move_crate.appendAssumeCapacity(stacks.crates[from - 1].pop());
        }

        //move the  count crates into the `move_crate`
        var move_to_count: usize = 0;
        while (move_to_count < quantity) : (move_to_count += 1) {
            stacks.crates[to - 1].appendAssumeCapacity(move_crate.pop());
        }
    }

    //get top stack
    const top = stacks.top();
    log.info("{s}", .{top});
    return top;
}

test part2 {
    try testing.expectEqual(
        [9]u8{ 'W', 'Z', 'M', 'F', 'V', 'G', 'G', 'Z', 'P' },
        part2(),
    );
}
