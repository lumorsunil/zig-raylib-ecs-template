const Game = @import("../game.zig").Game;
const TopDown = @import("top-down.zig").TopDown;

pub const Box2D_TopDown = struct {
    pub const CControllable = TopDown.CControllable;
    pub const SControllable = TopDown.SControllable;
    pub const Input = TopDown.Input;
    pub const Physics = @import("../systems/physics-box2d.zig").Physics;
    pub const Body = @import("../components/body.zig").Body;
    pub const WorldVector = Game.Vector2;

    pub const demo_mod = @import("../demo-box2d.zig");

    pub const gravity = TopDown.gravity;
    pub const air_drag_x = TopDown.air_drag_x;
    pub const air_drag_y = TopDown.air_drag_y;

    pub const is_box2d = true;
};
