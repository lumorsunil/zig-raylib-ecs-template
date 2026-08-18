const Game = @import("../game.zig").Game;

pub const Platformer = struct {
    pub const CControllable = @import("../components/controllable/platformer.zig").ControllablePlatformer;
    pub const SControllable = @import("../systems/controllable/platformer.zig").ControllablePlatformer;
    pub const Input = @import("../systems/input/platformer.zig").InputPlatformer;
    pub const Physics = @import("../systems/physics.zig").Physics(.{ .enable_separate_axis_update = true });
    pub const Body = @import("../components/body.zig").Body;
    pub const WorldVector = Game.L.Vector2;

    pub const demo_mod = @import("../demo.zig");

    pub const gravity = Game.L.V.v2(0, 1000);
    pub const air_drag_x = 15;
    pub const air_drag_y = 0;

    pub const is_box2d = false;
};
