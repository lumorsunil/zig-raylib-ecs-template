const Game = @import("../../game.zig").Game;

pub const ControllablePlatformer = struct {
    speed: f32 = 15,
    jump_strength: f32 = 300,
    coyote_time_ends_at: f64 = 0,
    last_jump_count: usize = 0,
    jump_count: usize = 1,
    last_is_on_ground: bool = false,
    in_air_reason: InAirReason = .none,

    pub const coyote_time_duration = 0.1;

    pub const InAirReason = enum { none, jump, fall };

    pub fn init() @This() {
        return .{};
    }

    pub fn canJump(self: @This(), body: Game.C.Body, t: f64) bool {
        if (self.jump_count <= self.last_jump_count) return false;
        if (body.is_on_ground) return true;
        if (self.in_air_reason == .fall and self.coyote_time_ends_at > t) return true;
        return false;
    }
};
