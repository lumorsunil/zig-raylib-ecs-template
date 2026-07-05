const std = @import("std");
const Game = @import("../game.zig").Game;

pub const RelativePosition = struct {
    enabled: bool = true,

    pub fn init() @This() {
        return .{};
    }

    pub fn update(_: *RelativePosition, game: *Game) void {
        var it = game.entityIterator(.{ Game.C.RelativePosition, Game.C.Body }, .{});

        while (it.next()) |ctx| {
            const relative_position = ctx.get(Game.C.RelativePosition);
            relative_position.has_been_processed = false;
        }

        it.reset();
        while (it.next()) |ctx| {
            const relative_position = ctx.get(Game.C.RelativePosition);

            if (!relative_position.anchoree.valid()) {
                if (relative_position.destroy_when_parent_is_destroyed) {
                    ctx.destroy();
                }

                continue;
            }

            process(ctx);
        }
    }

    fn process(ctx: Game.EntityContext) void {
        const relative_position = ctx.get(Game.C.RelativePosition);

        if (relative_position.has_been_processed) return;

        relative_position.has_been_processed = true;

        if (relative_position.anchoree.has(Game.C.RelativePosition)) {
            process(relative_position.anchoree);
        }

        const body = ctx.get(Game.C.Body);
        const anchoree_body = relative_position.anchoree.getConst(Game.C.Body);
        body.position = anchoree_body.position.add(relative_position.offset);
    }
};
