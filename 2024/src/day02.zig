const std = @import("std");
const consts = @import("consts.zig");
const log = std.log;
const testing = std.testing;

const Game = enum(u8) {
    Rock = 1,
    Paper = 2,
    Scissors = 3,
};

const GameOutcome = enum(u8) {
    Lost = 0,
    Draw = 3,
    Win = 6,
};

// zig fmt: off
const Player = enum {
    //Opponent
    A, B, C,
    //Me
    X, Y, Z,
};
// zig fmt: on

const stringToEnum = std.meta.stringToEnum;

pub fn part1() usize {
    const data = @embedFile("data/day02.txt");
    const total_score_1 = rockPaperSissorsInitialStrategy(data);
    std.log.info(
        "The total score would be {} if everything goes exactly according to your strategy guide.",
        .{total_score_1},
    );
    return total_score_1;
}

pub fn part2() usize {
    const data = @embedFile("data/day02.txt");
    const total_score_2 = rockPaperSissorsFinalStrategy(data);
    std.log.info(
        "Now that I'm correctly decrypting the ultra top secret strategy guide, I get a total score of {}",
        .{total_score_2},
    );
    return total_score_2;
}

fn rockPaperSissorsInitialStrategy(data: []const u8) usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var total_score_1: usize = 0;
    while (lines.next()) |line| {
        var players = if (line.len != consts.EMPTY) std.mem.splitScalar(u8, line, ' ') else {
            if (line.len == consts.EMPTY) break;
            unreachable;
        };
        const opponent = stringToEnum(Player, players.first()).?;
        const me = stringToEnum(Player, players.next().?).?;
        const game_hand_1, const outcome_1 = playRockPaperSissors1(opponent, me);
        total_score_1 += @intFromEnum(game_hand_1) + @intFromEnum(outcome_1);
    }

    return total_score_1;
}

fn playRockPaperSissors1(opponent: Player, me: Player) struct { Game, GameOutcome } {
    var player_game = std.EnumArray(Player, Game).initUndefined();
    player_game.set(.A, .Rock);
    player_game.set(.B, .Paper);
    player_game.set(.C, .Scissors);
    player_game.set(.X, .Rock);
    player_game.set(.Y, .Paper);
    player_game.set(.Z, .Scissors);

    const player_1 = player_game.get(opponent);
    const player_2 = player_game.get(me);

    switch (player_1) {
        .Rock => switch (player_2) {
            .Rock => return .{ player_2, .Draw },
            .Paper => return .{ player_2, .Win },
            .Scissors => return .{ player_2, .Lost },
        },
        .Paper => switch (player_2) {
            .Rock => return .{ player_2, .Lost },
            .Paper => return .{ player_2, .Draw },
            .Scissors => return .{ player_2, .Win },
        },
        .Scissors => switch (player_2) {
            .Rock => return .{ player_2, .Win },
            .Paper => return .{ player_2, .Lost },
            .Scissors => return .{ player_2, .Draw },
        },
    }
}

fn rockPaperSissorsFinalStrategy(data: []const u8) usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var total_score_2: usize = 0;
    while (lines.next()) |line| {
        var players = if (line.len != consts.EMPTY) std.mem.splitScalar(u8, line, ' ') else {
            if (line.len == consts.EMPTY) break;
            unreachable;
        };
        const opponent = stringToEnum(Player, players.first()).?;
        const me = stringToEnum(Player, players.next().?).?;
        const game_hand_2, const outcome_2 = playRockPaperSissors2(opponent, me);
        total_score_2 += @intFromEnum(game_hand_2) + @intFromEnum(outcome_2);
    }

    return total_score_2;
}

fn playRockPaperSissors2(opponent: Player, me: Player) struct { Game, GameOutcome } {
    var opponent_hand = std.EnumArray(Player, Game).initUndefined();
    opponent_hand.set(.A, .Rock);
    opponent_hand.set(.B, .Paper);
    opponent_hand.set(.C, .Scissors);

    var my_outcome = std.EnumArray(Player, GameOutcome).initUndefined();
    my_outcome.set(.X, .Lost);
    my_outcome.set(.Y, .Draw);
    my_outcome.set(.Z, .Win);

    const player_1 = opponent_hand.get(opponent);
    const player_2 = my_outcome.get(me);

    switch (player_1) {
        .Rock => switch (player_2) {
            .Lost => return .{ .Scissors, .Lost },
            .Draw => return .{ .Rock, .Draw },
            .Win => return .{ .Paper, .Win },
        },
        .Paper => switch (player_2) {
            .Lost => return .{ .Rock, .Lost },
            .Draw => return .{ .Paper, .Draw },
            .Win => return .{ .Scissors, .Win },
        },
        .Scissors => switch (player_2) {
            .Lost => return .{ .Paper, .Lost },
            .Draw => return .{ .Scissors, .Draw },
            .Win => return .{ .Rock, .Win },
        },
    }
}

test part1 {
    try testing.expectEqual(@as(usize, 11603), part1());

    const data =
        \\A Y
        \\B X
        \\C Z
        \\
    ;
    try std.testing.expectEqual(@as(usize, 15), rockPaperSissorsInitialStrategy(data));
}

test part2 {
    try testing.expectEqual(@as(usize, 12725), part2());

    const data =
        \\A Y
        \\B X
        \\C Z
        \\
    ;
    try std.testing.expectEqual(@as(usize, 12), rockPaperSissorsFinalStrategy(data));
}
