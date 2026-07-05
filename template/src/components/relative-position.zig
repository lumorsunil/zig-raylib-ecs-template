const Game = @import("../game.zig").Game;

pub const RelativePosition = struct {
    anchoree: Game.EntityContext,
    offset: Game.Vector,
    destroy_when_parent_is_destroyed: bool,
    has_been_processed: bool = false,

    pub fn init(
        anchoree: Game.EntityContext,
        offset: Game.Vector,
        destroy_when_parent_is_destroyed: bool,
    ) @This() {
        return .{
            .anchoree = anchoree,
            .offset = offset,
            .destroy_when_parent_is_destroyed = destroy_when_parent_is_destroyed,
        };
    }
};
