const std = @import("std");
const Game = @import("game.zig").Game;

pub fn main(init: std.process.Init) !void {
    var game = Game.init(init);
    defer game.deinit();
    std.process.exit(setupAndRun(&game));
}

fn setupAndRun(game: *Game) u8 {
    game.setup() catch |err| {
        std.log.err("Failed to setup game: {}", .{err});
        return 1;
    };
    game.run();
    return 0;
}
