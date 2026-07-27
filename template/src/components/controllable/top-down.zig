const Game = @import("../../game.zig").Game;

pub const ControllableTopDown = struct {
    enabled: bool = true,
    speed: f32 = 200,

    pub fn init() @This() {
        return .{};
    }
};
