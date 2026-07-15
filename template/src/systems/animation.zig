const Game = @import("../game.zig").Game;

pub const Animation = struct {
    enabled: bool = true,

    pub fn init() @This() {
        return .{};
    }

    pub fn update(_: *Animation, game: *Game) void {
        var it = game.entityIterator(.{ Game.C.Animation, Game.C.Renderable }, .{});

        while (it.next()) |ctx| {
            const animation = ctx.get(Game.C.Animation);

            const event = animation.update(game.elapsedTime());
            if (animation.isDone()) return;

            switch (event) {
                .next_frame, .looped => {
                    const renderable = ctx.get(Game.C.Renderable);
                    renderable.* = animation.getFrame();
                },
                .none => {},
            }
        }
    }
};
