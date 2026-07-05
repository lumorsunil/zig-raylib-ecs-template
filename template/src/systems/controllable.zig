const Game = @import("../game.zig").Game;

pub const Controllable = struct {
    enabled: bool = true,

    pub fn init() @This() {
        return .{};
    }

    pub fn update(_: *Controllable, game: *Game) void {
        var it = game.entityIterator(.{ Game.C.Controllable, Game.C.Body, Game.C.Renderable }, .{});
        const input = game.input();

        while (it.next()) |ctx| {
            const body = ctx.get(Game.C.Body);
            const controllable = ctx.get(Game.C.Controllable);

            body.velocity.x = input.left_x_axis * controllable.speed;
            body.velocity.y = input.left_y_axis * controllable.speed;

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
        }
    }
};
