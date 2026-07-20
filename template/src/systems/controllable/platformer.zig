const Game = @import("../../game.zig").Game;

pub const ControllablePlatformer = struct {
    enabled: bool = true,

    pub fn init() @This() {
        return .{};
    }

    pub fn update(_: *@This(), game: *Game) void {
        const t = game.elapsedTime();
        var it = game.entityIterator(.{ Game.C.Controllable, Game.C.Body, Game.C.Renderable }, .{});
        const input = game.input();

        while (it.next()) |ctx| {
            const body = ctx.get(Game.C.Body);
            const controllable = ctx.get(Game.C.Controllable);

            defer controllable.last_is_on_ground = body.is_on_ground;

            if (input.isDown(.move_right)) {
                body.velocity.x += controllable.speed;
            }
            if (input.isDown(.move_up)) {
                body.velocity.y -= controllable.speed;
            }
            if (input.isDown(.move_left)) {
                body.velocity.x -= controllable.speed;
            }
            if (input.isDown(.move_down)) {
                body.velocity.y += controllable.speed;
            }
            if (input.isPressed(.jump)) {
                controllable.jump_count += 1;
            }
            if (body.is_on_ground) {
                controllable.in_air_reason = .none;
            }
            if (input.isDown(.jump) and controllable.canJump(body.*, t)) {
                body.velocity.y = -controllable.jump_strength;
                controllable.last_jump_count = controllable.jump_count;
                controllable.coyote_time_ends_at = t - 1;
                controllable.in_air_reason = .jump;
            }
            if (controllable.last_is_on_ground and !body.is_on_ground and controllable.in_air_reason == .none) {
                controllable.in_air_reason = .fall;
                controllable.coyote_time_ends_at = t + Game.C.Controllable.coyote_time_duration;
            }
        }
    }
};
