const Game = @import("../../game.zig").Game;

pub const ControllableTopDown = struct {
    enabled: bool = true,

    pub fn init() @This() {
        return .{};
    }

    pub fn update(_: *@This(), game: *Game) void {
        var it = game.entityIterator(.{ Game.C.Controllable, Game.C.Body, Game.C.Renderable }, .{});
        const input = game.input();

        while (it.next()) |ctx| {
            const body = ctx.get(Game.C.Body);
            const controllable = ctx.get(Game.C.Controllable);

            body.acceleration.x += input.leftXAxis() * controllable.speed;
            body.acceleration.y += input.leftYAxis() * controllable.speed;

            if (input.isDown(.move_right)) {
                body.acceleration.x += controllable.speed;
            }
            if (input.isDown(.move_up)) {
                body.acceleration.y -= controllable.speed;
            }
            if (input.isDown(.move_left)) {
                body.acceleration.x -= controllable.speed;
            }
            if (input.isDown(.move_down)) {
                body.acceleration.y += controllable.speed;
            }
        }
    }
};
