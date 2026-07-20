const std = @import("std");
const Game = @import("../../game.zig").Game;
const rl = @import("raylib");
const InputGeneric = @import("../input.zig").InputGeneric;

pub const InputTopDown = struct {
    generic: Input = .init(),

    pub const Action = enum {
        move_right,
        move_up,
        move_left,
        move_down,
    };

    const Input = InputGeneric(Action, .init(.{
        .left_face_right, // move_right
        .left_face_up, // move_up
        .left_face_left, // move_left
        .left_face_down, // move_down
    }, .{
        .d, // move_right
        .w, // move_up
        .a, // move_left
        .s, // move_down
    }));

    pub fn init() @This() {
        return .{};
    }

    pub fn update(self: *@This()) void {
        self.generic.updateSticks();
    }

    pub fn isDown(self: @This(), action: Action) bool {
        return self.generic.isDown(action);
    }

    pub fn isPressed(self: @This(), action: Action) bool {
        return self.generic.isPressed(action);
    }

    pub fn isReleased(self: @This(), action: Action) bool {
        return self.generic.isReleased(action);
    }

    pub fn leftXAxis(self: @This()) f32 {
        return self.generic.left_x_axis;
    }

    pub fn leftYAxis(self: @This()) f32 {
        return self.generic.left_y_axis;
    }

    pub fn rightXAxis(self: @This()) f32 {
        return self.generic.right_x_axis;
    }

    pub fn rightYAxis(self: @This()) f32 {
        return self.generic.right_y_axis;
    }
};
