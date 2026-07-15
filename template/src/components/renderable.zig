const std = @import("std");
const Game = @import("../game.zig").Game;
const rl = @import("raylib");

pub const Renderable = union(enum) {
    rectangle: Rectangle,
    circle: Circle,
    triangle: Triangle,
    sprite: Sprite,
    polygon: Polygon,

    pub fn draw(self: Renderable, position: Game.Vector, rotation: f32) void {
        switch (self) {
            inline else => |s| s.draw(position, rotation),
        }
    }

    pub fn size(self: Renderable, rotation: f32) Game.Vector {
        return switch (self) {
            inline else => |s| s.size(rotation),
        };
    }

    pub fn initRectangle(rec_size: Game.Vector, color: Game.Color) @This() {
        return .{ .rectangle = .{ .rec_size = rec_size, .color = color } };
    }

    pub fn initCircle(radius: f32, color: Game.Color) @This() {
        return .{ .circle = .{ .radius = radius, .color = color } };
    }

    pub fn initTriangle(
        v1: Game.Vector,
        v2: Game.Vector,
        v3: Game.Vector,
        color: Game.Color,
    ) @This() {
        return .{ .triangle = .{ .v1 = v1, .v2 = v2, .v3 = v3, .color = color } };
    }

    pub fn initSprite(texture: rl.Texture2D, source: rl.Rectangle) @This() {
        return .{ .sprite = .{ .texture = texture, .source = source } };
    }

    pub fn initPolygon(points: []const Game.Vector, scale: f32, thickness: f32) @This() {
        return .{ .polygon = .{ .points = points, .scale = scale, .thickness = thickness } };
    }

    pub const Rectangle = struct {
        rec_size: Game.Vector,
        color: Game.Color,

        pub fn draw(self: Rectangle, position: Game.Vector, rotation: f32) void {
            rl.drawRectanglePro(.init(
                position.x,
                position.y,
                self.rec_size.x,
                self.rec_size.y,
            ), .init(0, 0), rotation, self.color);
        }

        pub fn size(self: Rectangle, _: f32) Game.Vector {
            return self.rec_size;
        }
    };

    pub const Circle = struct {
        radius: f32,
        color: Game.Color,

        pub fn draw(self: Circle, position: Game.Vector, _: f32) void {
            rl.drawCircleV(position, self.radius, self.color);
        }

        pub fn size(self: Circle, _: f32) Game.Vector {
            return .init(self.radius, self.radius);
        }
    };

    pub const Triangle = struct {
        v1: Game.Vector,
        v2: Game.Vector,
        v3: Game.Vector,
        color: Game.Color,

        pub fn draw(self: Triangle, position: Game.Vector, rotation: f32) void {
            const v1 = self.v1.rotate(rotation).add(position);
            const v2 = self.v2.rotate(rotation).add(position);
            const v3 = self.v3.rotate(rotation).add(position);
            rl.drawTriangle(v1, v2, v3, self.color);
        }

        pub fn size(self: Triangle, rotation: f32) Game.Vector {
            const v1 = self.v1.rotate(rotation);
            const v2 = self.v2.rotate(rotation);
            const v3 = self.v3.rotate(rotation);

            const min_x = @min(v1.x, v2.x, v3.x);
            const max_x = @max(v1.x, v2.x, v3.x);
            const min_y = @min(v1.y, v2.y, v3.y);
            const max_y = @max(v1.y, v2.y, v3.y);

            return .init(max_x - min_x, max_y - min_y);
        }
    };

    pub const Sprite = struct {
        texture: rl.Texture2D,
        source: rl.Rectangle,

        pub fn draw(self: Sprite, position: Game.Vector, rotation: f32) void {
            var dest = self.source;
            dest.x = position.x;
            dest.y = position.y;
            rl.drawTexturePro(self.texture, self.source, dest, .zero(), rotation, .white);
        }

        pub fn size(self: Sprite, _: f32) Game.Vector {
            return .init(self.source.width, self.source.height);
        }
    };

    pub const Polygon = struct {
        points: []const Game.Vector,
        thickness: f32 = 1,
        scale: f32 = 1,
        color: Game.Color = .white,

        pub fn draw(self: Polygon, position: Game.Vector, rotation: f32) void {
            for (0..self.points.len) |i| {
                const start = self.points[i].scale(self.scale).rotate(rotation).add(position);
                const end = self.points[(i + 1) % self.points.len].scale(self.scale).rotate(rotation).add(position);
                rl.drawLineEx(start, end, self.thickness, self.color);
            }
        }

        pub fn size(self: Polygon, rotation: f32) Game.Vector {
            var min_x = std.math.inf(f32);
            var max_x = -std.math.inf(f32);
            var min_y = std.math.inf(f32);
            var max_y = -std.math.inf(f32);

            for (self.points) |p| {
                const rp = p.rotate(rotation);
                min_x = @min(min_x, rp.x);
                max_x = @max(max_x, rp.x);
                min_y = @min(min_y, rp.y);
                max_y = @max(max_y, rp.y);
            }

            const min_max = Game.Vector.init(max_x - min_x, max_y - min_y);

            return min_max.scale(self.scale);
        }
    };
};
