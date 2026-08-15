const std = @import("std");
const Game = @import("../game.zig").Game;

pub const Physics = struct {
    enabled: bool = true,

    const sub_step_count = 4;

    pub const BackendImpl = @import("../physics-backend/box2d.zig").PhysicsBackendImplBox2D;
    pub const Axis = enum { x, y };

    pub fn init(_: *Game) @This() {
        return .{};
    }

    pub fn update(self: *@This(), game: *Game) void {
        const zone = Game.tracyZoneN(@src(), @typeName(@This()) ++ "." ++ @src().fn_name);
        defer zone.end();

        const time_step = game.physicsTimeStep();

        for (0..game.physics_frames) |_| {
            self.physicsFrame(game, time_step);
        }
    }

    fn physicsFrame(_: *@This(), game: *Game, time_step: f32) void {
        const frame_zone = Game.tracyZoneN(@src(), @src().fn_name);
        defer frame_zone.end();

        const world = game.getSingleton(Game.b2.b2WorldId);
        world.Step(time_step, sub_step_count);
    }
};
