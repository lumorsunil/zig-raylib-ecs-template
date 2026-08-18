const Game = @import("../game.zig").Game;
const ApplyTarget = Game.L.PhysicsBackend.ApplyTarget;
const ActionTarget = Game.L.PhysicsBackend.ActionTarget;
const ComputedTarget = Game.L.PhysicsBackend.ComputedTarget;

pub const PhysicsBackendImplBox2D = struct {
    pub fn Commit(comptime target: ApplyTarget) type {
        return struct {
            ctx: Game.L.EntityContext,
            el: target.ProviderElement(),

            pub fn init(ctx: Game.L.EntityContext, el: target.ProviderElement()) @This() {
                return .{
                    .ctx = ctx,
                    .el = el,
                };
            }

            pub fn ptr(self: *@This()) target.PtrElement() {
                if (comptime @TypeOf(self.el) == Game.L.Vector2) {
                    return .{ &self.el[0], &self.el[1] };
                } else {
                    return &self.el;
                }
            }

            pub fn commit(self: *@This()) void {
                const b2_body = self.ctx.getConst(Game.L.b2.b2BodyId);

                return switch (comptime target) {
                    // .acceleration_ => {},
                    .velocity_ => |dt| switch (dt) {
                        .x => {
                            var velocity = b2_body.GetLinearVelocity();
                            velocity.x = self.el;
                            b2_body.SetLinearVelocity(velocity);
                        },
                        .y => {
                            var velocity = b2_body.GetLinearVelocity();
                            velocity.y = self.el;
                            b2_body.SetLinearVelocity(velocity);
                        },
                        .xy => {
                            b2_body.SetLinearVelocity(Game.L.V.toB2(self.el));
                        },
                    },
                    .position_ => |dt| switch (dt) {
                        .x => {
                            var position = b2_body.GetPosition();
                            position.x = self.el;
                            b2_body.SetTransform(position, b2_body.GetRotation());
                        },
                        .y => {
                            var position = b2_body.GetPosition();
                            position.y = self.el;
                            b2_body.SetTransform(position, b2_body.GetRotation());
                        },
                        .xy => {
                            b2_body.SetTransform(Game.L.V.toB2(self.el), b2_body.GetRotation());
                        },
                    },
                    .rotation => {
                        b2_body.SetTransform(b2_body.GetPosition(), Game.L.b2.b2MakeRot(self.el));
                    },
                    .rotation_velocity => {
                        b2_body.SetAngularVelocity(self.el);
                    },
                };
            }
        };
    }

    pub fn Action(comptime target: ActionTarget) type {
        return struct {
            ctx: Game.L.EntityContext,

            pub fn init(ctx: Game.L.EntityContext) @This() {
                return .{ .ctx = ctx };
            }

            pub fn commit(self: @This(), value: target.ProviderElement()) void {
                const b2_body = self.ctx.getConst(Game.L.b2.b2BodyId);

                switch (target) {
                    .force_ => |dt| switch (dt) {
                        .x => b2_body.ApplyForceToCenter(.{ .x = value, .y = 0 }, true),
                        .y => b2_body.ApplyForceToCenter(.{ .x = 0, .y = value }, true),
                        .xy => b2_body.ApplyForceToCenter(Game.L.V.toB2(value), true),
                    },
                    .impulse_ => |dt| switch (dt) {
                        .x => b2_body.ApplyLinearImpulseToCenter(.{ .x = value, .y = 0 }, true),
                        .y => b2_body.ApplyLinearImpulseToCenter(.{ .x = 0, .y = value }, true),
                        .xy => b2_body.ApplyLinearImpulseToCenter(Game.L.V.toB2(value), true),
                    },
                }
            }
        };
    }

    pub fn getComputed(
        comptime target: ComputedTarget,
        ctx: Game.L.EntityContext,
    ) target.Element() {
        const b2_body = ctx.getConst(Game.L.b2.b2BodyId);

        return switch (target) {
            .size_ => |dt| switch (dt) {
                .x => b2_body.ComputeAABB().b2AABB_Extents().x * 2,
                .y => b2_body.ComputeAABB().b2AABB_Extents().y * 2,
                .xy => Game.L.V.from(b2_body.ComputeAABB().b2AABB_Extents()) * Game.L.V.scalar2(2),
            },
        };
    }

    pub fn getTargetComponent(
        comptime target: ApplyTarget,
        ctx: Game.L.EntityContext,
    ) Commit(target) {
        const b2_body = ctx.getConst(Game.L.b2.b2BodyId);

        const el: target.ProviderElement() = switch (comptime target) {
            // .acceleration_ => |dt| switch (comptime dt) {
            //     .x => container.acceleration_x.getPA(.from(index)),
            //     .y => container.acceleration_y.getPA(.from(index)),
            //     .xy => .{
            //         getTargetComponent(.acceleration(.x), ctx),
            //         getTargetComponent(.acceleration(.y), ctx),
            //     },
            // },
            .velocity_ => |dt| switch (comptime dt) {
                .x => b2_body.GetLinearVelocity().x,
                .y => b2_body.GetLinearVelocity().y,
                .xy => Game.L.V.from(b2_body.GetLinearVelocity()),
            },
            .position_ => |dt| switch (comptime dt) {
                .x => b2_body.GetPosition().x,
                .y => b2_body.GetPosition().y,
                .xy => Game.L.V.from(b2_body.GetPosition()),
            },
            .rotation => b2_body.GetRotation().GetAngle(),
            .rotation_velocity => b2_body.GetAngularVelocity(),
        };

        return .init(ctx, el);
    }

    pub fn getAction(
        comptime target: ActionTarget,
        ctx: Game.L.EntityContext,
    ) Action(target) {
        return .init(ctx);
    }
};
