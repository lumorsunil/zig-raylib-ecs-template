const Game = @import("game.zig").Game;
const rl = @import("raylib");

pub fn setup(self: *Game) void {
    initRaylib(self);

    createCamera(self);
    // createSpritesheet(self);
    createSystems(self);
    createDefaultGrid(self) catch unreachable;
    createPlayer(self);
}

fn initRaylib(self: *Game) void {
    const screen_size = self.screenSize();
    rl.initWindow(@intFromFloat(screen_size.x), @intFromFloat(screen_size.y), "Game Template");
    rl.setWindowPosition(24, 48);
    rl.setTargetFPS(self.fps());
}

fn createCamera(self: *Game) void {
    self.addSingleton(Game.Camera{
        .offset = .zero(),
        .target = .zero(),
        .rotation = 0,
        .zoom = self.zoom(),
    });
}

fn createSpritesheet(self: *Game) void {
    const spritesheet = rl.loadTexture("spritesheet.png") catch unreachable;
    self.addSingleton(spritesheet);
}

fn createSystems(self: *Game) void {
    self.addSingleton(Game.S.Input.init());
    self.addSingleton(Game.S.Physics.init());
    self.addSingleton(Game.S.Controllable.init());
    self.addSingleton(Game.S.DestroyEntities.init());
    self.addSingleton(Game.S.Camera.init());
    self.addSingleton(Game.S.RelativePosition.init());
}

fn createPlayer(self: *Game) void {
    const player = self.createEntity();
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
