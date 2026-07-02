const Game = @import("../game.zig").Game;

pub const Controllable = struct {
    speed: f32 = 100,

    pub fn init() @This() {
        return .{};
    }
};
