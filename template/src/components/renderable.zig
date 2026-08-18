const std = @import("std");
const Game = @import("../game.zig").Game;
const rl = @import("raylib");

pub const Renderable = union(enum) {
    rectangle: Rectangle,
    circle: Circle,
    triangle: Triangle,
    sprite: Sprite,
    polygon: Polygon,

    pub fn draw(self: Renderable, position: Game.L.Vector2, rotation: f32) void {
        switch (self) {
            inline else => |s| s.draw(position, rotation),
        }
    }

    pub fn size(self: Renderable, rotation: f32) Game.L.Vector2 {
        return switch (self) {
            inline else => |s| s.size(rotation),
        };
    }

    pub fn initRectangle(rec_size: Game.L.Vector2, color: Game.L.Color) @This() {
        return .{ .rectangle = .{ .rec_size = rec_size, .color = color } };
    }

    pub fn initCircle(radius: f32, color: Game.L.Color) @This() {
        return .{ .circle = .{ .radius = radius, .color = color } };
    }

    pub fn initTriangle(
        v1: Game.L.Vector2,
        v2: Game.L.Vector2,
        v3: Game.L.Vector2,
        color: Game.L.Color,
    ) @This() {
        return .{ .triangle = .{ .v1 = v1, .v2 = v2, .v3 = v3, .color = color } };
    }

    pub fn initSprite(texture: rl.Texture2D, source: rl.Rectangle) @This() {
        return .{ .sprite = .{ .texture = texture, .source = source } };
    }

    pub fn initPolygon(points: []const Game.L.Vector2, scale: f32, thickness: f32) @This() {
        return .{ .polygon = .{ .points = points, .scale = scale, .thickness = thickness } };
    }

    pub const Rectangle = struct {
        rec_size: Game.L.Vector2,
        color: Game.L.Color,

        pub fn draw(self: @This(), position: Game.L.Vector2, rotation: f32) void {
            rl.drawRectanglePro(
                Game.L.Rectangle.init(position, self.rec_size).toRl(),
                .init(0, 0),
                rotation,
                self.color,
            );
        }

        pub fn size(self: @This(), _: f32) Game.L.Vector2 {
            return self.rec_size;
        }
    };

    pub const Circle = struct {
        radius: f32,
        color: Game.L.Color,

        pub fn draw(self: Circle, position: Game.L.Vector2, _: f32) void {
            rl.drawCircleV(Game.L.V.toRl(position), self.radius, self.color);
        }

        pub fn size(self: Circle, _: f32) Game.L.Vector2 {
            return .init(self.radius, self.radius);
        }
    };

    pub const Triangle = struct {
        v1: Game.L.Vector2,
        v2: Game.L.Vector2,
        v3: Game.L.Vector2,
        color: Game.L.Color,

        pub fn draw(self: Triangle, position: Game.L.Vector2, rotation: f32) void {
            const v1 = Game.L.V.rotate(self.v1, rotation) + position;
            const v2 = Game.L.V.rotate(self.v2, rotation) + position;
            const v3 = Game.L.V.rotate(self.v3, rotation) + position;
            rl.drawTriangle(Game.L.V.toRl(v1), Game.L.V.toRl(v2), Game.L.V.toRl(v3), self.color);
        }

        pub fn size(self: Triangle, rotation: f32) Game.L.Vector2 {
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
        source: Game.L.Rectangle,

        pub fn draw(self: Sprite, position: Game.L.Vector2, rotation: f32) void {
            var dest = self.source;
            dest.position = position;
            rl.drawTexturePro(self.texture, self.source.toRl(), dest.toRl(), .zero(), rotation, .white);
        }

        pub fn size(self: Sprite, _: f32) Game.L.Vector2 {
            return .init(self.source.width, self.source.height);
        }
    };

    pub const Polygon = struct {
        points: []const Game.L.Vector2,
        thickness: f32 = 1,
        scale: f32 = 1,
        color: Game.L.Color = .white,

        pub fn draw(self: Polygon, position: Game.L.Vector2, rotation: f32) void {
            for (0..self.points.len) |i| {
                const start = position + Game.L.V.rotate(
                    self.points[i] * Game.L.V.scalar2(self.scale),
                    rotation,
                );
                const end = position + Game.L.V.rotate(
                    self.points[(i + 1) % self.points.len] * Game.L.V.scalar2(self.scale),
                    rotation,
                );
                rl.drawLineEx(Game.L.V.toRl(start), Game.L.V.toRl(end), self.thickness, self.color);
            }
        }

        pub fn size(self: Polygon, rotation: f32) Game.L.Vector2 {
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
