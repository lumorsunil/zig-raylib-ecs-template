const Game = @import("../game.zig").Game;

pub const Body = struct {
    enabled: bool = true,
    position: Game.Vector,
    velocity: Game.Vector = .init(0, 0),
    acceleration: Game.Vector = .init(0, 0),
    rotation: f32 = 0,
    angular_velocity: f32 = 0,

    air_drag_x: f32 = Game.Preset.air_drag_x,
    air_drag_y: f32 = Game.Preset.air_drag_y,

    lock_x: bool = false,
    lock_y: bool = false,
    is_on_ground: bool = false,

    pub fn init(position: Game.Vector) @This() {
        return .{
            .position = position,
        };
    }
};
