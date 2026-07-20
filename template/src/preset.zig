const Game = @import("game.zig").Game;
const CControllablePlatformer = @import("components/controllable/platformer.zig").ControllablePlatformer;
const CControllableTopDown = @import("components/controllable/top-down.zig").ControllableTopDown;
const SControllablePlatformer = @import("systems/controllable/platformer.zig").ControllablePlatformer;
const SControllableTopDown = @import("systems/controllable/top-down.zig").ControllableTopDown;
const InputPlatformer = @import("systems/input/platformer.zig").InputPlatformer;
const InputTopDown = @import("systems/input/top-down.zig").InputTopDown;

const Platformer = struct {
    pub const CControllable = CControllablePlatformer;
    pub const SControllable = SControllablePlatformer;
    pub const Input = InputPlatformer;

    pub const gravity = Game.Vector.init(0, 1000);
    pub const air_drag_x = 15;
    pub const air_drag_y = 0;
};

const TopDown = struct {
    pub const CControllable = CControllableTopDown;
    pub const SControllable = SControllableTopDown;
    pub const Input = InputTopDown;

    pub const gravity = Game.Vector.init(0, 0);
    pub const air_drag_x = 5;
    pub const air_drag_y = 5;
};

pub const Preset = TopDown;
