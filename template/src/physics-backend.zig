const Game = @import("game.zig").Game;
const Axis = Game.S.Physics.Axis;

pub const PhysicsBackend = struct {
    pub const Impl = Game.S.Physics.BackendImpl;

    pub const getComputed = Impl.getComputed;
    pub const getAction = Impl.getAction;
    pub const getTargetComponent = Impl.getTargetComponent;

    pub fn getProperty(
        comptime target: ApplyTarget,
        ctx: Game.L.EntityContext,
    ) target.ProviderElement() {
        var target_component = getTargetComponent(target, ctx);
        const ptr = target_component.ptr();

        if (@TypeOf(ptr) == struct { *f32, *f32 }) {
            return .{ ptr.@"0".*, ptr.@"1".* };
        } else {
            return ptr.*;
        }
    }

    pub fn applyToComponent(
        comptime target: ApplyTarget,
        ctx: Game.L.EntityContext,
        op: ApplyOperation(target.ProviderElement()),
    ) void {
        var target_component = getTargetComponent(target, ctx);
        applyOperation(target.ProviderElement(), target.PtrElement(), op, target_component.ptr());
        target_component.commit();
    }

    pub fn applyAction(
        comptime target: ActionTarget,
        ctx: Game.L.EntityContext,
        value: target.ProviderElement(),
    ) void {
        const action = getAction(target, ctx);
        action.commit(value);
    }

    pub const ComputedTarget = union(enum) {
        size_: DimensionType,

        pub fn Element(comptime self: @This()) type {
            return switch (comptime self) {
                .size_ => |dt| dt.ProviderElement(),
            };
        }

        pub fn size(dt: DimensionType) @This() {
            return .{ .size_ = dt };
        }
    };

    pub const ActionTarget = union(enum) {
        force_: DimensionType,
        impulse_: DimensionType,

        pub fn ProviderElement(comptime self: @This()) type {
            return switch (comptime self) {
                .force_ => |dt| dt.ProviderElement(),
                .impulse_ => |dt| dt.ProviderElement(),
            };
        }

        pub fn force(dt: DimensionType) @This() {
            return .{ .force_ = dt };
        }

        pub fn impulse(dt: DimensionType) @This() {
            return .{ .impulse_ = dt };
        }
    };

    pub const ApplyTarget = union(enum) {
        // acceleration_: DimensionType,
        velocity_: DimensionType,
        position_: DimensionType,
        rotation,
        rotation_velocity,

        pub fn ProviderElement(comptime self: @This()) type {
            return switch (comptime self) {
                // .acceleration_ => |dt| dt.ProviderElement(),
                .velocity_ => |dt| dt.ProviderElement(),
                .position_ => |dt| dt.ProviderElement(),
                .rotation => f32,
                .rotation_velocity => f32,
            };
        }

        pub fn PtrElement(comptime self: @This()) type {
            return switch (comptime self) {
                // .acceleration_ => |dt| dt.PtrElement(),
                .velocity_ => |dt| dt.PtrElement(),
                .position_ => |dt| dt.PtrElement(),
                .rotation => *f32,
                .rotation_velocity => *f32,
            };
        }

        pub const commit = Impl.commit;

        // pub fn acceleration(dt: DimensionType) @This() {
        //     return .{ .acceleration_ = dt };
        // }

        pub fn velocity(dt: DimensionType) @This() {
            return .{ .velocity_ = dt };
        }

        pub fn position(dt: DimensionType) @This() {
            return .{ .position_ = dt };
        }
    };

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
                .xy => Game.L.Vector2,
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
                        const v_op = @unionInit(ApplyOperation(Game.L.Vector2), @tagName(t), {});
                        var target_temp = Game.L.V.v2(target.@"0".*, target.@"1".*);
                        applyOperation(Game.L.Vector2, *Game.L.Vector2, v_op, &target_temp);
                        target.@"0".* = target_temp[0];
                        target.@"1".* = target_temp[1];
                    } else {
                        const v_op = @unionInit(ApplyOperation(Game.L.Vector2), @tagName(t), s);
                        var target_temp = Game.L.V.v2(target.@"0".*, target.@"1".*);
                        applyOperation(Game.L.Vector2, *Game.L.Vector2, v_op, &target_temp);
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
};
