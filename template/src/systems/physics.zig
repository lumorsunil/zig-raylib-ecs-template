const Game = @import("../game.zig").Game;

pub const Physics = struct {
    enabled: bool = true,

    pub fn init() @This() {
        return .{};
    }

    pub fn update(_: *Physics, game: *Game) void {
        var it = game.entityIterator(.{Game.C.Body}, .{});

        while (it.next()) |ctx| {
            const body = ctx.get(Game.C.Body);
            if (!body.enabled) continue;
            body.velocity = body.velocity.add(body.acceleration.scale(game.deltaTime()));
            body.position = body.position.add(body.velocity.scale(game.deltaTime()));
            body.rotation += body.angular_velocity * game.deltaTime();

            body.acceleration = .init(0, 0);
        }
    }
};
