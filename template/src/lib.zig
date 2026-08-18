const rl = @import("raylib");

pub const Preset = @import("preset.zig").Preset;

pub const Mode = enum { normal, debug };

pub const ScreenState = union(enum) {
    menu,
    gameplay,
    game_over,
    ending,
};

pub const tracy = @import("tracy.zig");
pub const ztracy = tracy.ztracy;
pub const ZoneCtx = tracy.ZoneCtx;
pub const tracyZoneN = tracy.tracyZoneN;
pub const tracyZoneNC = tracy.tracyZoneNC;

pub const Assets = @import("assets.zig").Assets;

pub const vector_mod = @import("vector.zig");
pub const V = vector_mod.V;
pub const Vector2 = vector_mod.Vector2;
pub const Vector3 = vector_mod.Vector3;
pub const Vector4 = vector_mod.Vector4;
pub const WorldVector = @import("preset.zig").Preset.WorldVector;
pub const Rectangle = @import("rectangle.zig").Rectangle;

pub const PhysicsBackend = @import("physics-backend.zig").PhysicsBackend;
pub const b2 = @import("box2d");

pub const PerlinNoise2D = @import("utils/perlin-noise.zig").PerlinNoise2D;

pub const Camera = rl.Camera2D;
// pub const Vector2 = rl.Vector2;
pub const Color = rl.Color;
pub const Texture = rl.Texture2D;
pub const Image = rl.Image;
pub const Sound = rl.Sound;
pub const Music = rl.Music;
pub const Shader = rl.Shader;
pub const RenderBuffer = @import("render-buffer.zig").RenderBuffer;

const sm_mod = @import("systems/state-machine.zig");
pub const StateFunction = sm_mod.StateFunction;
pub const StateMachineContext = sm_mod.StateMachineContext;

pub const EntityContext = @import("entity-context.zig").EntityContext;
pub const EntityIterator = @import("entity-iterator.zig").EntityIterator;
