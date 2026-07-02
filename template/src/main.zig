const std = @import("std");
const Game = @import("game.zig").Game;

pub fn main(init: std.process.Init) !void {
    var game = Game.init(init);
    defer game.deinit();
    game.setup();
    game.run();
}
