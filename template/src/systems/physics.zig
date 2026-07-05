const std = @import("std");
const Game = @import("../game.zig").Game;
const rl = @import("raylib");

pub const PhysicsOptions = struct {
    enable_separate_axis_update: bool = false,
};

pub const Axis = enum { x, y };

pub fn Physics(comptime options: PhysicsOptions) type {
    return struct {
        enabled: bool = true,
        grid: ?DefaultGrid = null,

        const grid_mod = @import("physics/grid.zig");
        pub const Grid = grid_mod.Grid;
        pub const DefaultGrid = grid_mod.DefaultGrid;
        pub const DefaultCell = grid_mod.DefaultCell;

        pub fn init() @This() {
            return .{};
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            if (self.grid) |*grid| grid.deinit(allocator);
        }

        pub fn update(self: *@This(), game: *Game) void {
            var it = game.entityIterator(.{Game.C.Body}, .{});

            while (it.next()) |ctx| {
                const body = ctx.get(Game.C.Body);
                if (!body.enabled) continue;

                body.velocity = body.velocity.add(body.acceleration.scale(game.deltaTime()));
                body.rotation += body.angular_velocity * game.deltaTime();

                if (comptime options.enable_separate_axis_update) {
                    self.updateAxis(game, body, &.{.x});
                    if (self.grid) |*grid| grid.resolveCollisions(game, ctx, body, &.{.x});
                    self.updateAxis(game, body, &.{.y});
                    if (self.grid) |*grid| grid.resolveCollisions(game, ctx, body, &.{.y});
                } else {
                    self.updateAxis(game, body, &.{ .x, .y });
                    if (self.grid) |*grid| grid.resolveCollisions(game, ctx, body, &.{ .x, .y });
                }

                body.acceleration = .init(0, 0);
            }
        }

        pub fn updateAxis(_: *@This(), game: *Game, body: *Game.C.Body, comptime axiis: []const Axis) void {
            inline for (comptime axiis) |axis| {
                switch (comptime axis) {
                    .x => {
                        if (!body.lock_x) {
                            body.position.x += body.velocity.x * game.deltaTime();
                        }
                    },
                    .y => {
                        if (!body.lock_y) {
                            body.position.y += body.velocity.y * game.deltaTime();
                        }
                    },
                }
            }
        }
    };
}
