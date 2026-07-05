const std = @import("std");
const Game = @import("../game.zig").Game;
const rl = @import("raylib");

pub const Hitbox = struct {
    hitbox: rl.Rectangle,

    pub fn init(offset: Game.Vector, size_: Game.Vector) @This() {
        return .{ .hitbox = .init(offset.x, offset.y, size_.x, size_.y) };
    }

    pub fn position(self: Hitbox) Game.Vector {
        return .init(self.hitbox.x, self.hitbox.y);
    }

    pub fn setPosition(self: *Hitbox, new_position: Game.Vector) void {
        self.hitbox.x = new_position.x;
        self.hitbox.y = new_position.y;
    }

    pub fn size(self: Hitbox) Game.Vector {
        return .init(self.hitbox.width, self.hitbox.height);
    }

    pub fn setSize(self: *Hitbox, new_size: Game.Vector) void {
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
