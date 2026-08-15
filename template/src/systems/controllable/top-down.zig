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

            if (!controllable.enabled) continue;

            var force = Game.V.v2(input.leftXAxis(), input.leftYAxis());

            if (input.isDown(.move_right)) {
                force[0] += 1;
            }
            if (input.isDown(.move_up)) {
                force[1] -= 1;
            }
            if (input.isDown(.move_left)) {
                force[0] -= 1;
            }
            if (input.isDown(.move_down)) {
                force[1] += 1;
            }

            body.applyForce(force * Game.V.scalar2(controllable.speed));
        }
    }
};
