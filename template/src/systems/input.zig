const std = @import("std");
const rl = @import("raylib");
const Game = @import("../game.zig").Game;

pub const Input = Game.Preset.Input;

pub fn InputGenericOptions(comptime Action: type) type {
    const ActionMap = [std.meta.tags(Action).len]rl.GamepadButton;
    const AlternativeMap = [std.meta.tags(Action).len]rl.KeyboardKey;

    return struct {
        action_map: ActionMap,
        alternative_map: AlternativeMap,

        pub fn init(action_map: ActionMap, alternative_map: AlternativeMap) @This() {
            return .{
                .action_map = action_map,
                .alternative_map = alternative_map,
            };
        }
    };
}

pub fn InputGeneric(
    comptime Action: type,
    comptime options: InputGenericOptions(Action),
) type {
    return struct {
        left_x_axis: f32 = 0,
        left_y_axis: f32 = 0,
        right_x_axis: f32 = 0,
        right_y_axis: f32 = 0,
        left_stick_deadzone: f32 = 0.2,
        right_stick_deadzone: f32 = 0.2,

        pub fn init() @This() {
            return .{};
        }

        pub fn updateSticks(self: *@This()) void {
            self.left_x_axis = rl.getGamepadAxisMovement(0, .left_x);
            self.applyDeadzone(&self.left_x_axis, self.left_stick_deadzone);
            self.left_y_axis = rl.getGamepadAxisMovement(0, .left_y);
            self.applyDeadzone(&self.left_y_axis, self.left_stick_deadzone);

            self.right_x_axis = rl.getGamepadAxisMovement(0, .right_x);
            self.applyDeadzone(&self.right_x_axis, self.right_stick_deadzone);
            self.right_y_axis = rl.getGamepadAxisMovement(0, .right_y);
            self.applyDeadzone(&self.right_y_axis, self.right_stick_deadzone);
        }

        pub fn applyDeadzone(_: @This(), axis: *f32, deadzone: f32) void {
            if (axis.* < 0 and axis.* > -deadzone) {
                axis.* = 0;
            } else if (axis.* > 0 and axis.* < deadzone) {
                axis.* = 0;
            }
        }

        pub fn isDown(self: @This(), action: Action) bool {
            if (rl.isGamepadButtonDown(0, self.mapAction(action))) return true;
            if (rl.isKeyDown(self.mapActionAlternative(action))) return true;
            return false;
        }

        pub fn isPressed(self: @This(), action: Action) bool {
            if (rl.isGamepadButtonPressed(0, self.mapAction(action))) return true;
            if (rl.isKeyPressed(self.mapActionAlternative(action))) return true;
            return false;
        }

        pub fn isReleased(self: @This(), action: Action) bool {
            if (rl.isGamepadButtonReleased(0, self.mapAction(action))) return true;
            if (rl.isKeyReleased(self.mapActionAlternative(action))) return true;
            return false;
        }

        fn mapAction(_: @This(), action: Action) rl.GamepadButton {
            return options.action_map[@intFromEnum(action)];
        }

        fn mapActionAlternative(_: @This(), action: Action) rl.KeyboardKey {
            return options.alternative_map[@intFromEnum(action)];
        }
    };
}
