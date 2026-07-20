const Game = @import("../../game.zig").Game;

pub const ControllableTopDown = struct {
    speed: f32 = 200,

    pub fn init() @This() {
        return .{};
    }
};
