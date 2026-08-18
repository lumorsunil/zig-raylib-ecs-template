const Game = @import("game.zig").Game;
const ecs = @import("ecs");

pub fn EntityIterator(comptime includes: anytype, comptime excludes: anytype) type {
    const View, const Iterator = comptime brk: {
        if (includes.len == 1 and excludes.len == 0) break :brk .{ ecs.BasicView(includes[0]), ecs.utils.ReverseSliceIterator(ecs.Entity) };
        break :brk .{ ecs.MultiView(includes, excludes), ecs.MultiView(includes, excludes).Iterator };
    };

    return struct {
        game: *Game,
        view: View,
        it: ?Iterator = null,

        pub fn init(game: *Game, view: View) @This() {
            return .{ .game = game, .view = view };
        }

        pub fn next(self: *@This()) ?Game.L.EntityContext {
            const it = self.getIt();
            const entity = it.next() orelse return null;
            return .init(self.game, entity);
        }

        pub fn reset(self: *@This()) void {
            const it = self.getIt();
            it.reset();
        }

        fn getIt(self: *@This()) *Iterator {
            if (self.it) |*it| return it;
            self.it = self.view.entityIterator();
            return &(self.it.?);
        }
    };
}
