const std = @import("std");
const rl = @import("raylib");

pub const Vector2 = @Vector(2, f32);
pub const Vector3 = @Vector(3, f32);
pub const Vector4 = @Vector(4, f32);

pub const V = struct {
    fn ToRl(comptime T: type) type {
        return switch (T) {
            Vector2 => rl.Vector2,
            Vector3 => rl.Vector3,
            Vector4 => rl.Vector4,
            else => @compileError("Invalid input type, needs to be a vector"),
        };
    }

    pub fn toRl(v: anytype) ToRl(@TypeOf(v)) {
        return @bitCast(v);
    }

    fn FromRl(comptime T: type) type {
        return switch (T) {
            rl.Vector2 => Vector2,
            rl.Vector3 => Vector3,
            rl.Vector4 => Vector4,
            else => @compileError("Invalid input type, needs to be a vector"),
        };
    }

    fn fromRl(v: anytype) FromRl(@TypeOf(v)) {
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
                return fromRl(@field(ToRl(@TypeOf(v)), decl_name)(toRl(v)));
            }
        }.f;
    }

    fn map1(comptime decl_name: []const u8) @TypeOf(id1) {
        return struct {
            pub fn f(v: anytype, u: @TypeOf(v)) @TypeOf(v) {
                return fromRl(@field(ToRl(@TypeOf(v)), decl_name)(v, u));
            }
        }.f;
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

    pub fn scalar(comptime T: type, s: f32) T {
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

    pub fn rotate(v: anytype, r: f32) @TypeOf(v) {
        return fromRl(toRl(v).rotate(r));
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
