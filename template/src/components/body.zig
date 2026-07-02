const Game = @import("../game.zig").Game;

pub const Body = struct {
    enabled: bool = true,
    position: Game.Vector,
    velocity: Game.Vector = .init(0, 0),
    acceleration: Game.Vector = .init(0, 0),
    rotation: f32 = 0,
    angular_velocity: f32 = 0,

    pub fn init(position: Game.Vector) @This() {
        return .{
            .position = position,
        };
    }
};
