const std = @import("std");
const Game = @import("game.zig").Game;
const rl = @import("raylib");

pub const Rectangle = struct {
    position: Game.L.Vector2,
    size: Game.L.Vector2,

    pub fn init(position: Game.L.Vector2, size: Game.L.Vector2) @This() {
        return .{ .position = position, .size = size };
    }

    pub fn toRl(self: @This()) rl.Rectangle {
        return .init(self.position[0], self.position[1], self.size[0], self.size[1]);
    }

    pub fn fromRl(rec: rl.Rectangle) @This() {
        return @bitCast(rec);
    }

    pub fn min(self: @This()) Game.L.Vector2 {
        return self.position;
    }

    pub fn max(self: @This()) Game.L.Vector2 {
        return self.position + self.size;
    }

    /// Check collision between two rectangles
    pub fn checkCollision(self: @This(), rec2: @This()) bool {
        return rl.checkCollisionRecs(self.toRl(), rec2.toRl());
    }

    /// Get collision rectangle for two rectangles collision
    pub fn getCollision(self: @This(), rec2: @This()) @This() {
        return fromRl(rl.getCollisionRec(self.toRl(), rec2.toRl()));
    }

    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        try writer.print("Rectangle{{({}), ({})}}", .{ self.position, self.size });
    }
};
