const Game = @import("game.zig").Game;

pub fn createDemo(game: *Game) !void {
    try createDefaultGrid(game);
    createPlayer(game);
}

fn createPlayer(game: *Game) void {
    const player = game.createEntity();
    player.add(Game.C.Renderable.initRectangle(.init(16, 16), .white));
    player.add(Game.C.Body.init(.init(150, 128)));
    player.add(Game.C.Controllable.init());
}

fn createDefaultGrid(self: *Game) !void {
    const grid = try Game.S.Physics.DefaultGrid.init(self.allocator, 10, 8);

    for (0..grid.width) |x| {
        for (0..grid.height) |y| {
            const cell = &grid.data[x + y * grid.width];

            if (y == grid.height - 2 and x > 0 and x < grid.width - 1) {
                cell.is_solid = true;
            } else {
                cell.is_solid = false;
            }
        }
    }

    self.physics().grid = grid;
}
