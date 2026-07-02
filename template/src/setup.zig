const Game = @import("game.zig").Game;
const rl = @import("raylib");

pub fn setup(self: *Game) void {
    const screen_size = self.screenSize();
    rl.initWindow(@intFromFloat(screen_size.x), @intFromFloat(screen_size.y), "Game Template");
    rl.setWindowPosition(24, 48);
    rl.setTargetFPS(self.fps());

    self.addSingleton(Game.Camera{
        .offset = .zero(),
        .target = .zero(),
        .rotation = 0,
        .zoom = self.zoom(),
    });
    self.addSingleton(Game.S.Input.init());
    self.addSingleton(Game.S.Physics.init());
    self.addSingleton(Game.S.Controllable.init());
    self.addSingleton(Game.S.DestroyEntities.init());
    // const spritesheet = rl.loadTexture("spritesheet.png") catch unreachable;
    // self.addSingleton(spritesheet);
    self.addSingleton(Game.S.Camera.init());

    const player = self.createEntity();
    player.add(Game.C.Renderable.initRectangle(.init(16, 16), .white));
    player.add(Game.C.Body.init(.init(150, 128)));
    player.add(Game.C.Controllable.init());
}
