const std = @import("std");
const Allocator = std.mem.Allocator;
const rl = @import("raylib");
const Game = @import("../../game.zig").Game;
const VectorArrayList = @import("vector-array-list.zig").VectorArrayList;

const VAL_B_len = 64;
const VAL = VectorArrayList(f32, 0, .default);
const VAL_B = VectorArrayList(bool, false, .{ .custom = VAL_B_len });
const VA = VAL.Vector;
const VA_B = VAL_B.Vector;
const Vector = Game.Vector2;
const Axis = Game.S.Physics.Axis;

pub const BodyContainer = struct {
    allocator: Allocator,
    gravity_factor: VAL = .empty,
    acceleration_x: VAL = .empty,
    acceleration_y: VAL = .empty,
    velocity_x: VAL = .empty,
    velocity_y: VAL = .empty,
    position_x: VAL = .empty,
    position_y: VAL = .empty,
    rotation: VAL = .empty,
    rotation_velocity: VAL = .empty,
    drag_factor: VAL = .empty,
    size_x: VAL = .empty,
    size_y: VAL = .empty,

    pub fn init(allocator: Allocator) @This() {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *@This()) void {
        const allocator = self.allocator;
        inline for (std.meta.fields(@This())) |field| {
            if (@hasDecl(field.type, "deinit")) {
                @field(self, field.name).deinit(allocator);
            }
        }
    }

    pub fn setBody(
        self: *@This(),
        i: usize,
        pos: Vector,
        vel: Vector,
        acc: Vector,
        r: f32,
        rv: f32,
        size: Vector,
        is_static: bool,
    ) void {
        const allocator = self.allocator;
        self.gravity_factor.set(allocator, i, if (is_static) 0 else 1, null);
        self.position_x.set(allocator, i, pos[0], null);
        self.position_y.set(allocator, i, pos[1], null);
        self.velocity_x.set(allocator, i, vel[0], null);
        self.velocity_y.set(allocator, i, vel[1], null);
        self.acceleration_x.set(allocator, i, acc[0], null);
        self.acceleration_y.set(allocator, i, acc[1], null);
        self.rotation.set(allocator, i, r, null);
        self.rotation_velocity.set(allocator, i, rv, null);
        self.drag_factor.set(allocator, i, 1, null);
        self.size_x.set(allocator, i, size[0], null);
        self.size_y.set(allocator, i, size[1], null);
    }

    fn integrateScaledFn(dt: f32, a: *VA, b: *VA) void {
        const splat = @as(VA, @splat(dt));

        a.* += b.* * splat;
    }

    fn integrateScaled(dt: f32, a: *VAL, b: *VAL) void {
        a.iterateC(f32, b, dt, integrateScaledFn);
    }

    fn applyGravityFn(gravity: *const VA, acceleration: *VA, gravity_factor: *const VA) void {
        acceleration.* += gravity.* * gravity_factor.*;
    }

    fn applyGravity(self: *@This(), gravity: Vector) void {
        const gravity_x_vector = @as(VA, @splat(gravity[0]));
        self.acceleration_x.iterateC(
            *const VA,
            &self.gravity_factor,
            &gravity_x_vector,
            applyGravityFn,
        );
        const gravity_y_vector = @as(VA, @splat(gravity[1]));
        self.acceleration_y.iterateC(
            *const VA,
            &self.gravity_factor,
            &gravity_y_vector,
            applyGravityFn,
        );
    }

    fn applyDragFn(drag_factor: *const VA, velocity: *VA, entity_drag_factor: *const VA) void {
        // v = v - v * factor

        const factor = entity_drag_factor.* * drag_factor.*;
        velocity.* -= velocity.* * factor;
    }

    fn applyDrag(self: *@This(), val: *VAL, drag_factor: f32, dt: f32) void {
        @setRuntimeSafety(false);

        const factor = drag_factor * dt;
        const factor_v = @as(VA, @splat(factor));

        val.iterateC(*const VA, &self.drag_factor, &factor_v, applyDragFn);
    }

    pub fn startPhysicsFrame(self: *@This(), gravity: Vector) void {
        @setRuntimeSafety(false);

        self.applyGravity(gravity);
    }

    pub fn endPhysicsFrame(self: *@This()) void {
        @setRuntimeSafety(false);

        self.acceleration_x.setScalar(0);
        self.acceleration_y.setScalar(0);
    }

    pub fn updatePositions(self: *@This(), drag_factor: f32, dt: f32, comptime axis: Axis) void {
        @setRuntimeSafety(false);

        const frame_zone = Game.tracyZoneN(@src(), @src().fn_name ++ "(" ++ @tagName(axis) ++ ")");
        defer frame_zone.end();

        switch (comptime axis) {
            .x => {
                integrateScaled(dt, &self.velocity_x, &self.acceleration_x);
                self.applyDrag(&self.velocity_x, drag_factor, dt);
                integrateScaled(dt, &self.position_x, &self.velocity_x);
            },
            .y => {
                integrateScaled(dt, &self.velocity_y, &self.acceleration_y);
                self.applyDrag(&self.velocity_y, drag_factor, dt);
                integrateScaled(dt, &self.position_y, &self.velocity_y);
            },
        }
    }

    pub fn updateRotation(self: *@This(), drag_factor: f32, dt: f32) void {
        @setRuntimeSafety(false);

        const frame_zone = Game.tracyZoneN(@src(), @src().fn_name);
        defer frame_zone.end();

        self.applyDrag(&self.rotation_velocity, drag_factor, dt);
        integrateScaled(dt, &self.rotation, &self.rotation_velocity);
    }

    pub const IntersectionIterator = struct {
        intersections: VAL_B,
        v_index: usize = 0,
        e_index: usize = 0,

        pub fn init(intersections: VAL_B) @This() {
            return .{ .intersections = intersections };
        }

        pub fn next(self: *@This()) ?usize {
            while (self.v_index < self.intersections.list.items.len) {
                const v_ = self.intersections.list.items[self.v_index];
                const v: [VAL_B_len]bool = v_;

                // if (rl.isKeyPressed(.space)) {
                //     const intersections = @reduce(.Add, @as(@Vector(64, u8), @intFromBool(v_)));
                //     std.log.debug("v{} intersections: {}", .{ self.v_index, intersections });
                //     std.log.debug("{any}", .{@intFromBool(v_)});
                // }

                while (self.e_index < v.len) {
                    const i = self.e_index;
                    self.e_index += 1;
                    if (v[i]) return i + self.v_index * VAL_B_len;
                }

                self.v_index += 1;
                self.e_index = 0;
            }

            return null;
        }

        pub fn deinit(self: *@This(), allocator: Allocator) void {
            self.intersections.deinit(allocator);
        }
    };

    pub fn intersectionsRec(self: *@This(), rec: rl.Rectangle) IntersectionIterator {
        var result: VAL_B = .{
            .list = std.ArrayList(VA_B).initCapacity(
                self.allocator,
                self.position_x.list.items.len,
            ) catch unreachable,
        };
        result.list.expandToCapacity();

        const left: VA = @splat(rec.x);
        const right: VA = @splat(rec.x + rec.width);
        const top: VA = @splat(rec.y);
        const bottom: VA = @splat(rec.y + rec.height);

        for (0..result.list.items.len) |i| {
            const position_x = &self.position_x.list.items[i];
            const position_y = &self.position_y.list.items[i];
            const size_x = &self.size_x.list.items[i];
            const size_y = &self.size_y.list.items[i];
            const result_v = &result.list.items[i];

            const entity_left = position_x.*;
            const entity_right = position_x.* + size_x.*;
            const entity_top = position_y.*;
            const entity_bottom = position_y.* + size_y.*;

            const left_result = left < entity_right;
            const right_result = right > entity_left;
            const top_result = top < entity_bottom;
            const bottom_result = bottom > entity_top;

            result_v.* = left_result & right_result & top_result & bottom_result;
        }

        return .init(result);
    }

    // pub fn intersectionsRec(self: *@This(), rec: rl.Rectangle) void {
    //     const left_v = @as(VA, @splat(rec.x));
    //     const right_v = @as(VA, @splat(rec.x + rec.width));
    //     const top_v = @as(VA, @splat(rec.y));
    //     const bottom_v = @as(VA, @splat(rec.y + rec.height));
    //
    //     const capacity = self.position_x.list.items.len;
    //
    //     var left_result = VAL_B.initCapacity(self.allocator, capacity);
    //     var right_result = VAL_B.initCapacity(self.allocator, capacity);
    //     var top_result = VAL_B.initCapacity(self.allocator, capacity);
    //     var bottom_result = VAL_B.initCapacity(self.allocator, capacity);
    //
    //     self.position_x.iterateC2(*const VA_B, &self.size_x, &left_result, &left_v, intersectionsMinFn);
    //     self.position_x.iterateC(*const VA_B, &right_result, &right_v, intersectionsMaxFn);
    //     self.position_y.iterateC2(*const VA_B, &self.size_y, &top_result, &top_v, intersectionsMinFn);
    //     self.position_y.iterateC(*const VA_B, &bottom_result, &bottom_v, intersectionsMaxFn);
    //
    //     var final_result = VAL_B.initCapacity(self.allocator, capacity);
    //
    //     final_result.iterate4(&left_result, &right_result, &top_result, &bottom_result, intersectionsFinalFn);
    // }
    //
    // fn intersectionsMinFn(min: *const VA, position: *VA, size: *VA, result: *VA) void {
    //     const max = position.* + size.*;
    //     result.* = min.* < max.*;
    // }
    //
    // fn intersectionsMaxFn(max: *const VA, position: *VA, result: *VA) void {
    //     result.* = max.* > position.*;
    // }
    //
    // fn intersectionsFinalFn(result: *VA, left: *VA, right: *VA, top: *VA, bottom: *VA) void {
    //     result.* = left.*
    // }
};
