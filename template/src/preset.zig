const Game = @import("game.zig").Game;

const Platformer = @import("presets/platformer.zig").Platformer;
const TopDown = @import("presets/top-down.zig").TopDown;
const Box2D_Platformer = @import("presets/box2d-platformer.zig").Box2D_Platformer;
const Box2D_TopDown = @import("presets/box2d-top-down.zig").Box2D_TopDown;

pub const Preset = Box2D_TopDown;
