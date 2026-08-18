const std = @import("std");
const Allocator = std.mem.Allocator;
const Game = @import("../game.zig").Game;
const rl = @import("raylib");

pub const PhysicsOptions = struct {
    enable_separate_axis_update: bool = false,
};

pub fn Physics(comptime options: PhysicsOptions) type {
    return struct {
        enabled: bool = true,
        gravity: Game.L.Vector2 = Game.L.Preset.gravity,
        grid: ?DefaultGrid = null,
        container: BodyContainer,

        pub const BackendImpl = @import("../physics-backend/container.zig").PhysicsBackendImplContainer;

        const grid_mod = @import("physics/grid.zig");
        pub const Grid = grid_mod.Grid;
        pub const DefaultGrid = grid_mod.DefaultGrid;
        pub const DefaultCell = grid_mod.DefaultCell;

        pub const Axis = enum { x, y };

        pub const BodyContainer = @import("physics/body-container.zig").BodyContainer;

        pub fn init(game: *Game) @This() {
            return .{
                .container = .init(game.allocator),
            };
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            if (self.grid) |*grid| grid.deinit(allocator);
            self.container.deinit();
        }

        pub fn update(self: *@This(), game: *Game) void {
            const zone = Game.L.tracyZoneN(@src(), @typeName(@This()) ++ "." ++ @src().fn_name);
            defer zone.end();

            const time_step = game.physicsTimeStep();

            self.container.startPhysicsFrame(self.gravity);

            for (0..game.physics_frames) |_| {
                self.physicsFrame(game, time_step);
            }

            self.container.endPhysicsFrame();
        }

        fn physicsFrame(self: *@This(), game: *Game, time_step: f32) void {
            const frame_zone = Game.L.tracyZoneN(@src(), @src().fn_name);
            defer frame_zone.end();

            self.updateBodyContainer(game, time_step);
        }

        fn updateBodyContainer(self: *@This(), game: *Game, time_step: f32) void {
            const frame_zone = Game.L.tracyZoneN(@src(), @src().fn_name);
            defer frame_zone.end();

            const drag_factor = 3;

            if (options.enable_separate_axis_update) {
                self.container.updatePositions(drag_factor, time_step, .x);
                self.resolveCollisions(game, &.{.x});
                self.container.updatePositions(drag_factor, time_step, .y);
                self.resolveCollisions(game, &.{.y});
            } else {
                self.container.updatePositions(drag_factor, time_step, .x);
                self.container.updatePositions(drag_factor, time_step, .y);
                self.resolveCollisions(game, &.{ .x, .y });
            }
            self.container.updateRotation(drag_factor, time_step);
        }

        fn resolveCollisions(
            self: *@This(),
            game: *Game,
            comptime axiis: []const Axis,
        ) void {
            const grid = if (self.grid) |*grid| grid else return;
            var it = game.entityIterator(.{Game.C.Body}, .{});
            while (it.next()) |ctx| {
                const body = ctx.get(Game.C.Body);
                body.is_on_ground = false;
                grid.resolveCollisions(game, ctx, body, onCollision, axiis);
            }
        }

        fn onCollision(
            _: Game.L.EntityContext,
            body: *Game.C.Body,
            event: DefaultGrid.ResolveCollisionEvent,
        ) void {
            switch (event) {
                .none => {},
                .collision => |collision| {
                    if (collision.axis == .y and collision.direction == 1) {
                        body.is_on_ground = true;
                    }
                },
            }
        }
    };
}
