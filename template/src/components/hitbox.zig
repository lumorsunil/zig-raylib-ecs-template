const std = @import("std");
const Game = @import("../game.zig").Game;
const rl = @import("raylib");

pub const Hitbox = struct {
    hitbox: Game.Rectangle,

    pub fn init(offset: Game.Vector2, size_: Game.Vector2) @This() {
        return .{ .hitbox = .init(offset, size_) };
    }

    pub fn position(self: Hitbox) Game.Vector2 {
        return self.hitbox.position;
    }

    pub fn setPosition(self: *Hitbox, new_position: Game.Vector2) void {
        self.hitbox.position = new_position;
    }

    pub fn size(self: Hitbox) Game.Vector2 {
        return self.hitbox.size;
    }

    pub fn setSize(self: *Hitbox, new_size: Game.Vector2) void {
        self.hitbox.width = new_size.x;
        self.hitbox.height = new_size.y;
    }

    pub fn checkCollision(self: Hitbox, other: anytype) bool {
        if (@TypeOf(other) == Hitbox) {
            return self.hitbox.checkCollision(other.hitbox);
        } else if (@TypeOf(other) == rl.Rectangle) {
            return self.hitbox.checkCollision(other);
        }

        @compileError("invalid argument for checkCollision: " ++ @typeName(@TypeOf(other)));
    }

    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        const p = self.position();
        const s = self.size();
        try writer.print("Hitbox{{({},{}) ({},{})}}", .{ p.x, p.y, s.x, s.y });
    }
};
