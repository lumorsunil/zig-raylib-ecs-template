const std = @import("std");
const Game = @import("../game.zig").Game;
const Axis = Game.S.Physics.Axis;

pub const Body = struct {
    enabled: bool = true,
    ctx: Game.EntityContext,
    lock_x: bool = false,
    lock_y: bool = false,
    is_on_ground: bool = false,

    pub fn init(ctx: Game.EntityContext, pos: Game.Vector2, siz: Game.Vector2) @This() {
        ctx.game.physics().container.setBody(
            ctx.entity.index,
            pos,
            .{ 0, 0 },
            .{ 0, 0 },
            0,
            0,
            siz,
            false,
        );

        return .{
            .ctx = ctx,
            // .position = position,
        };
    }

    fn getContainer(self: @This()) *Game.S.Physics.BodyContainer {
        return &self.ctx.game.physics().container;
    }

    fn getIndex(self: @This()) usize {
        return self.ctx.entity.index;
    }

    pub fn applyToComponent(
        self: @This(),
        comptime target: ApplyTarget,
        op: ApplyOperation(target.ProviderElement()),
    ) void {
        const target_component = self.getTargetComponent(target);
        applyOperation(target.ProviderElement(), target.PtrElement(), op, target_component);
    }

    pub fn getTargetComponent(self: @This(), comptime target: ApplyTarget) target.PtrElement() {
        return switch (comptime target) {
            .acceleration_ => |dt| switch (comptime dt) {
                .x => self.getContainer().acceleration_x.getPA(.from(self.getIndex())),
                .y => self.getContainer().acceleration_y.getPA(.from(self.getIndex())),
                .xy => .{
                    self.getTargetComponent(.acceleration(.x)),
                    self.getTargetComponent(.acceleration(.y)),
                },
            },
            .velocity_ => |dt| switch (comptime dt) {
                .x => self.getContainer().velocity_x.getPA(.from(self.getIndex())),
                .y => self.getContainer().velocity_y.getPA(.from(self.getIndex())),
                .xy => .{
                    self.getTargetComponent(.velocity(.x)),
                    self.getTargetComponent(.velocity(.y)),
                },
            },
            .position_ => |dt| switch (comptime dt) {
                .x => self.getContainer().position_x.getPA(.from(self.getIndex())),
                .y => self.getContainer().position_y.getPA(.from(self.getIndex())),
                .xy => .{
                    self.getTargetComponent(.position(.x)),
                    self.getTargetComponent(.position(.y)),
                },
            },
            .rotation => self.getContainer().rotation.getPA(.from(self.getIndex())),
            .rotation_velocity => self.getContainer().rotation_velocity.getPA(.from(self.getIndex())),
        };
    }

    pub const ApplyTarget = union(enum) {
        acceleration_: DimensionType,
        velocity_: DimensionType,
        position_: DimensionType,
        rotation,
        rotation_velocity,

        pub const DimensionType = enum {
            x,
            y,
            xy,

            pub fn from(axis: Axis) @This() {
                return switch (axis) {
                    .x => .x,
                    .y => .y,
                };
            }

            pub fn ProviderElement(comptime self: @This()) type {
                return switch (self) {
                    .x => f32,
                    .y => f32,
                    .xy => Game.Vector2,
                };
            }

            pub fn PtrElement(comptime self: @This()) type {
                return switch (self) {
                    .x => *f32,
                    .y => *f32,
                    .xy => struct { *f32, *f32 },
                };
            }
        };

        pub fn ProviderElement(comptime self: ApplyTarget) type {
            return switch (comptime self) {
                .acceleration_ => |dt| dt.ProviderElement(),
                .velocity_ => |dt| dt.ProviderElement(),
                .position_ => |dt| dt.ProviderElement(),
                .rotation => f32,
                .rotation_velocity => f32,
            };
        }

        pub fn PtrElement(comptime self: ApplyTarget) type {
            return switch (comptime self) {
                .acceleration_ => |dt| dt.PtrElement(),
                .velocity_ => |dt| dt.PtrElement(),
                .position_ => |dt| dt.PtrElement(),
                .rotation => *f32,
                .rotation_velocity => *f32,
            };
        }

        pub fn acceleration(dt: DimensionType) @This() {
            return .{ .acceleration_ = dt };
        }

        pub fn velocity(dt: DimensionType) @This() {
            return .{ .velocity_ = dt };
        }

        pub fn position(dt: DimensionType) @This() {
            return .{ .position_ = dt };
        }
    };

    fn applyOperation(
        comptime ProviderElement: type,
        comptime PtrElement: type,
        op: ApplyOperation(ProviderElement),
        target: PtrElement,
    ) void {
        if (comptime PtrElement == struct { *f32, *f32 }) {
            switch (op) {
                inline else => |s, t| {
                    if (@TypeOf(s) == void) {
                        const v_op = @unionInit(ApplyOperation(Game.Vector2), @tagName(t), {});
                        var target_temp = Game.V.v2(target.@"0".*, target.@"1".*);
                        applyOperation(Game.Vector2, *Game.Vector2, v_op, &target_temp);
                        target.@"0".* = target_temp[0];
                        target.@"1".* = target_temp[1];
                    } else {
                        const v_op = @unionInit(ApplyOperation(Game.Vector2), @tagName(t), s);
                        var target_temp = Game.V.v2(target.@"0".*, target.@"1".*);
                        applyOperation(Game.Vector2, *Game.Vector2, v_op, &target_temp);
                        target.@"0".* = target_temp[0];
                        target.@"1".* = target_temp[1];
                    }
                },
            }

            return;
        }

        switch (op) {
            .set_ => |value| target.* = value,
            .add_ => |value| target.* += value,
            .subtract_ => |value| target.* -= value,
            .multiply_ => |value| target.* *= value,
            .divide_ => |value| target.* /= value,
            .round => target.* = @round(target.*),
            .floor => target.* = @floor(target.*),
            .ceil => target.* = @ceil(target.*),
            .apply_ => |f| target.* = f(target.*),
        }
    }

    pub fn ApplyOperation(comptime ProviderElement: type) type {
        return union(enum) {
            set_: ProviderElement,
            add_: ProviderElement,
            subtract_: ProviderElement,
            multiply_: ProviderElement,
            divide_: ProviderElement,
            round,
            floor,
            ceil,
            apply_: *const fn (ProviderElement) ProviderElement,

            pub fn set(value: ProviderElement) @This() {
                return .{ .set_ = value };
            }

            pub fn add(value: ProviderElement) @This() {
                return .{ .add_ = value };
            }

            pub fn subtract(value: ProviderElement) @This() {
                return .{ .subtract_ = value };
            }

            pub fn multiply(value: ProviderElement) @This() {
                return .{ .multiply_ = value };
            }

            pub fn divide(value: ProviderElement) @This() {
                return .{ .divide_ = value };
            }

            pub fn apply(f: *const fn (ProviderElement) ProviderElement) @This() {
                return .{ .apply_ = f };
            }
        };
    }

    pub fn position(self: @This()) Game.Vector2 {
        const x = self.getContainer().position_x.get(self.getIndex());
        const y = self.getContainer().position_y.get(self.getIndex());

        return .{ x, y };
    }

    pub fn velocity(self: @This()) Game.Vector2 {
        const x = self.getContainer().velocity_x.get(self.getIndex());
        const y = self.getContainer().velocity_y.get(self.getIndex());

        return .{ x, y };
    }

    pub fn acceleration(self: @This()) Game.Vector2 {
        const x = self.getContainer().acceleration_x.get(self.getIndex());
        const y = self.getContainer().acceleration_y.get(self.getIndex());

        return .{ x, y };
    }

    pub fn rotation(self: @This()) f32 {
        return self.getContainer().rotation.get(self.getIndex());
    }

    pub fn size(self: @This()) Game.Vector2 {
        const x = self.getContainer().size_x.get(self.getIndex());
        const y = self.getContainer().size_y.get(self.getIndex());
        return .{ x, y };
    }

    pub fn enableDrag(self: @This()) void {
        self.getContainer().drag_factor.set(self.ctx.game.allocator, self.getIndex(), 1, null);
    }

    pub fn disableDrag(self: @This()) void {
        self.getContainer().drag_factor.set(self.ctx.game.allocator, self.getIndex(), 0, null);
    }

    pub fn setDragFactor(self: @This(), new_factor: f32) void {
        self.getContainer().drag_factor.set(self.ctx.game.allocator, self.getIndex(), new_factor, null);
    }
};
