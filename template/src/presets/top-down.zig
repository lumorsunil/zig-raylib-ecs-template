const Game = @import("../game.zig").Game;

pub const TopDown = struct {
    pub const CControllable = @import("../components/controllable/top-down.zig").ControllableTopDown;
    pub const SControllable = @import("../systems/controllable/top-down.zig").ControllableTopDown;
    pub const Input = @import("../systems/input/top-down.zig").InputTopDown;
    pub const Physics = @import("../systems/physics.zig").Physics(.{ .enable_separate_axis_update = true });
    pub const Body = @import("../components/body.zig").Body;
    pub const WorldVector = Game.Vector2;

    pub const demo_mod = @import("../demo.zig");

    pub const gravity = Game.V.v2(0, 0);
    pub const air_drag_x = 5;
    pub const air_drag_y = 5;

    pub const is_box2d = false;
};
