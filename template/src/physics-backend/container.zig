const Game = @import("../game.zig").Game;
const ApplyTarget = Game.PhysicsBackend.ApplyTarget;
const ActionTarget = Game.PhysicsBackend.ActionTarget;
const ComputedTarget = Game.PhysicsBackend.ComputedTarget;

fn getContainer(ctx: Game.EntityContext) *Game.S.Physics.BodyContainer {
    return &ctx.game.getSingleton(Game.S.Physics).container;
}

pub const PhysicsBackendImplContainer = struct {
    pub fn Commit(comptime target: ApplyTarget) type {
        return struct {
            ctx: Game.EntityContext,
            ptr_: target.PtrElement(),

            pub fn init(ctx: Game.EntityContext, ptr_: target.PtrElement()) @This() {
                return .{
                    .ctx = ctx,
                    .ptr_ = ptr_,
                };
            }

            pub fn ptr(self: *const @This()) target.PtrElement() {
                return self.ptr_;
            }

            pub fn commit(_: @This()) void {}
        };
    }

    pub fn Action(comptime target: ActionTarget) type {
        return struct {
            ctx: Game.EntityContext,

            pub fn init(ctx: Game.EntityContext) @This() {
                return .{ .ctx = ctx };
            }

            pub fn commit(self: @This(), value: target.ProviderElement()) void {
                const container = getContainer(self.ctx);
                const index = self.ctx.entity.index;

                switch (target) {
                    .force_ => |dt| switch (dt) {
                        .x => container.applyForce(index, .{ value, 0 }),
                        .y => container.applyForce(index, .{ 0, value }),
                        .xy => container.applyForce(index, value),
                    },
                    .impulse_ => |dt| switch (dt) {
                        .x => container.applyImpulse(index, .{ value, 0 }),
                        .y => container.applyImpulse(index, .{ 0, value }),
                        .xy => container.applyImpulse(index, value),
                    },
                }
            }
        };
    }

    pub fn getComputed(
        comptime target: ComputedTarget,
        ctx: Game.EntityContext,
    ) target.Element() {
        const container = getContainer(ctx);
        const index = ctx.entity.index;

        return switch (target) {
            .size_ => |dt| switch (dt) {
                .x => container.size_x.get(index),
                .y => container.size_y.get(index),
                .xy => .{
                    container.size_x.get(index),
                    container.size_y.get(index),
                },
            },
        };
    }

    pub fn getTargetComponent(
        comptime target: ApplyTarget,
        ctx: Game.EntityContext,
    ) Commit(target) {
        const container = getContainer(ctx);
        const index = ctx.entity.index;

        const ptr: target.PtrElement() = switch (comptime target) {
            // .acceleration_ => |dt| switch (comptime dt) {
            //     .x => container.acceleration_x.getPA(.from(index)),
            //     .y => container.acceleration_y.getPA(.from(index)),
            //     .xy => .{
            //         getTargetComponent(.acceleration(.x), ctx),
            //         getTargetComponent(.acceleration(.y), ctx),
            //     },
            // },
            .velocity_ => |dt| switch (comptime dt) {
                .x => container.velocity_x.getPA(.from(index)),
                .y => container.velocity_y.getPA(.from(index)),
                .xy => .{
                    getTargetComponent(.velocity(.x), ctx).ptr_,
                    getTargetComponent(.velocity(.y), ctx).ptr_,
                },
            },
            .position_ => |dt| switch (comptime dt) {
                .x => container.position_x.getPA(.from(index)),
                .y => container.position_y.getPA(.from(index)),
                .xy => .{
                    getTargetComponent(.position(.x), ctx).ptr_,
                    getTargetComponent(.position(.y), ctx).ptr_,
                },
            },
            .rotation => container.rotation.getPA(.from(index)),
            .rotation_velocity => container.rotation_velocity.getPA(.from(index)),
        };

        return .init(ctx, ptr);
    }

    pub fn getAction(
        comptime target: ActionTarget,
        ctx: Game.EntityContext,
    ) Action(target) {
        return .init(ctx);
    }
};
