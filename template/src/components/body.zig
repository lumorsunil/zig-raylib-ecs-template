const std = @import("std");
const Game = @import("../game.zig").Game;
const Axis = Game.S.Physics.Axis;

pub const Body = struct {
    ctx: Game.L.EntityContext,
    is_on_ground: bool = false,

    pub fn init(ctx: Game.L.EntityContext) @This() {
        return .{ .ctx = ctx };
    }

    pub fn applyToComponent(
        self: *@This(),
        comptime target: Game.L.PhysicsBackend.ApplyTarget,
        op: Game.L.PhysicsBackend.ApplyOperation(target.ProviderElement()),
    ) void {
        Game.L.PhysicsBackend.applyToComponent(target, self.ctx, op);
    }

    pub fn applyForce(self: *@This(), force: Game.L.WorldVector) void {
        Game.L.PhysicsBackend.applyAction(.force(.xy), self.ctx, force);
    }

    pub fn applyImpulse(self: *@This(), impulse: Game.L.WorldVector) void {
        Game.L.PhysicsBackend.applyAction(.impulse(.xy), self.ctx, impulse);
    }

    pub const getComputed = Game.L.PhysicsBackend.getComputed;
    pub const getTargetComponent = Game.L.PhysicsBackend.getTargetComponent;
    pub const getProperty = Game.L.PhysicsBackend.getProperty;

    pub fn position(self: @This()) Game.L.Vector2 {
        return getProperty(.position(.xy), self.ctx);
    }

    pub fn velocity(self: @This()) Game.L.Vector2 {
        return getProperty(.velocity(.xy), self.ctx);
    }

    // pub fn acceleration(self: @This()) Game.L.Vector2 {
    //     const target = getTargetComponent(.acceleration(.xy), self.ctx);
    //     return .{ target.ptr.@"0".*, target.ptr.@"1".* };
    // }

    pub fn rotation(self: @This()) f32 {
        return getProperty(.rotation, self.ctx);
    }

    pub fn size(self: @This()) Game.L.Vector2 {
        return getComputed(.size(.xy), self.ctx);
    }

    // pub fn enableDrag(self: @This()) void {
    //     self.getContainer().drag_factor.set(self.ctx.game.allocator, self.getIndex(), 1, null);
    // }
    //
    // pub fn disableDrag(self: @This()) void {
    //     self.getContainer().drag_factor.set(self.ctx.game.allocator, self.getIndex(), 0, null);
    // }
    //
    // pub fn setDragFactor(self: @This(), new_factor: f32) void {
    //     self.getContainer().drag_factor.set(self.ctx.game.allocator, self.getIndex(), new_factor, null);
    // }
};
