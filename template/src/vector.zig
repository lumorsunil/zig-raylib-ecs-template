const std = @import("std");
const rl = @import("raylib");
const b2 = @import("box2d");

pub const Vector2 = @Vector(2, f32);
pub const Vector3 = @Vector(3, f32);
pub const Vector4 = @Vector(4, f32);

pub const V = struct {
    fn ToRl(comptime T: type) type {
        return switch (T) {
            Vector2 => rl.Vector2,
            Vector3 => rl.Vector3,
            Vector4 => rl.Vector4,
            b2.b2Vec2 => rl.Vector2,
            else => @compileError("Invalid input type, needs to be a vector"),
        };
    }

    pub fn toRl(v: anytype) ToRl(@TypeOf(v)) {
        if (comptime @TypeOf(v) == b2.b2Vec2) {
            return .{ .x = v.x, .y = v.y };
        } else {
            return @bitCast(v);
        }
    }

    fn ToB2(comptime T: type) type {
        return switch (T) {
            Vector2, rl.Vector2 => b2.b2Vec2,
            else => @compileError("Invalid input type, needs to be a vector"),
        };
    }

    pub fn toB2(v: anytype) ToB2(@TypeOf(v)) {
        if (@typeInfo(@TypeOf(v)) == .vector) {
            if (@typeInfo(@TypeOf(v)).vector.len == 2) {
                return .{ .x = v[0], .y = v[1] };
            }
        } else {
            return @bitCast(v);
        }
    }

    fn From(comptime T: type) type {
        return switch (T) {
            rl.Vector2, b2.b2Vec2 => Vector2,
            rl.Vector3 => Vector3,
            rl.Vector4 => Vector4,
            else => @compileError("Invalid input type, needs to be a vector"),
        };
    }

    pub fn from(v: anytype) From(@TypeOf(v)) {
        return @bitCast(v);
    }

    fn id0(v: anytype) @TypeOf(v) {
        return v;
    }

    fn id1(v: anytype, _: @TypeOf(v)) @TypeOf(v) {
        return v;
    }

    fn map0(comptime decl_name: []const u8) @TypeOf(id0) {
        return struct {
            pub fn f(v: anytype) @TypeOf(v) {
                return from(@field(ToRl(@TypeOf(v)), decl_name)(toRl(v)));
            }
        }.f;
    }

    fn map1(comptime decl_name: []const u8) @TypeOf(id1) {
        return struct {
            pub fn f(v: anytype, u: @TypeOf(v)) @TypeOf(v) {
                return from(@field(ToRl(@TypeOf(v)), decl_name)(v, u));
            }
        }.f;
    }

    pub fn vec(comptime T: type, v: anytype) T {
        var v_: T = undefined;
        inline for (@typeInfo(T).vector.len) |d| {
            v_[d] = convertComponent(v[d]);
        }
        return v_;
    }

    pub fn v2(x: anytype, y: anytype) Vector2 {
        return .{ convertComponent(x), convertComponent(y) };
    }

    fn convertComponent(a: anytype) f32 {
        return switch (@typeInfo(@TypeOf(a))) {
            .int => @floatFromInt(a),
            .float => |f| if (f.bits != 32)
                @floatCast(a)
            else
                a,
            .comptime_int => @floatFromInt(a),
            .comptime_float => a,
            else => @compileError("invalid component type " ++ @typeName(@TypeOf(a))),
        };
    }

    pub fn v3(x: f32, y: f32, z: f32) Vector3 {
        return .{ x, y, z };
    }

    pub fn v4(x: f32, y: f32, z: f32, w: f32) Vector4 {
        return .{ x, y, z, w };
    }

    pub fn scalar(comptime T: type, s: @typeInfo(T).vector.child) T {
        return @splat(s);
    }

    pub fn scalar2(s: f32) Vector2 {
        return @splat(s);
    }

    pub fn scalar3(s: f32) Vector3 {
        return @splat(s);
    }

    pub fn scalar4(s: f32) Vector4 {
        return @splat(s);
    }

    pub const normalize = map0("normalize");

    pub fn length(v: anytype) f32 {
        return toRl(v).length();
    }

    pub fn distance(v: anytype, u: @TypeOf(v)) f32 {
        return toRl(v).distance(toRl(u));
    }

    pub fn rotate(v: anytype, r: f32) @TypeOf(v) {
        return from(toRl(v).rotate(r));
    }

    pub const max = map1("max");
    pub const min = map1("min");

    fn ToInt(comptime Int: type, comptime T: type) type {
        return @Vector(@typeInfo(T).vector.len, Int);
    }

    pub fn toInt(comptime T: type, v: anytype) ToInt(T, @TypeOf(v)) {
        return @intFromFloat(v);
    }

    fn FromInt(comptime T: type) type {
        return @Vector(@typeInfo(T).vector.len, f32);
    }

    pub fn fromInt(v: anytype) FromInt(@TypeOf(v)) {
        return @floatFromInt(v);
    }
};
