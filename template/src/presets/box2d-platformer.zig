const Game = @import("../game.zig").Game;
const Platformer = @import("platformer.zig").Platformer;

pub const Box2D_Platformer = struct {
    pub const CControllable = Platformer.CControllable;
    pub const SControllable = Platformer.SControllable;
    pub const Input = Platformer.Input;
    pub const Physics = @import("../systems/physics-box2d.zig").Physics;
    pub const Body = @import("../components/body.zig").Body;
    pub const WorldVector = Game.Vector2;

    pub const demo_mod = @import("../demo-box2d.zig");

    pub const gravity = Platformer.gravity;
    pub const air_drag_x = Platformer.air_drag_x;
    pub const air_drag_y = Platformer.air_drag_y;

    pub const is_box2d = true;
};
