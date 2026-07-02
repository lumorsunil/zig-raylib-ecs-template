const std = @import("std");
const Game = @import("../game.zig").Game;
const rl = @import("raylib");

pub const Input = struct {
    left_x_axis: f32 = 0,
    left_y_axis: f32 = 0,
    right_x_axis: f32 = 0,
    right_y_axis: f32 = 0,
    left_stick_deadzone: f32 = 0.2,
    right_stick_deadzone: f32 = 0.2,

    pub const Action = enum {
        shoot,
    };

    pub const action_map = [std.meta.tags(Action).len]rl.GamepadButton{
        .right_face_left, // shoot
    };

    pub fn init() @This() {
        return .{};
    }

    pub fn update(self: *Input) void {
        self.left_x_axis = rl.getGamepadAxisMovement(0, .left_x);
        applyDeadzone(&self.left_x_axis, self.left_stick_deadzone);
        self.left_y_axis = rl.getGamepadAxisMovement(0, .left_y);
        applyDeadzone(&self.left_y_axis, self.left_stick_deadzone);

        self.right_x_axis = rl.getGamepadAxisMovement(0, .right_x);
        applyDeadzone(&self.right_x_axis, self.right_stick_deadzone);
        self.right_y_axis = rl.getGamepadAxisMovement(0, .right_y);
        applyDeadzone(&self.right_y_axis, self.right_stick_deadzone);
    }

    fn applyDeadzone(axis: *f32, deadzone: f32) void {
        if (axis.* < 0 and axis.* > -deadzone) {
            axis.* = 0;
        } else if (axis.* > 0 and axis.* < deadzone) {
            axis.* = 0;
        }
    }

    pub fn isDown(self: @This(), action: Action) bool {
        return rl.isGamepadButtonDown(0, self.mapAction(action));
    }

    pub fn isPressed(self: @This(), action: Action) bool {
        return rl.isGamepadButtonPressed(0, self.mapAction(action));
    }

    pub fn isReleased(self: @This(), action: Action) bool {
        return rl.isGamepadButtonReleased(0, self.mapAction(action));
    }

    fn mapAction(_: @This(), action: Action) rl.GamepadButton {
        return action_map[@intFromEnum(action)];
    }
};
