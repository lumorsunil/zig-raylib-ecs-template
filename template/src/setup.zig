const std = @import("std");
const Game = @import("game.zig").Game;
const rl = @import("raylib");

pub fn setup(self: *Game) !void {
    try initRaylib(self);

    createCamera(self);
    initAssets(self, .load_all);
    createSystems(self);
    try @import("demo.zig").createDemo(self);

    self.elapsed_time = self.elapsedRealTime();
}

fn initRaylib(self: *Game) !void {
    const screen_size = self.screenSize();
    const screen_x: i32 = @intFromFloat(screen_size.x);
    const screen_y: i32 = @intFromFloat(screen_size.y);
    rl.initWindow(screen_x, screen_y, "Game Template");
    rl.setWindowPosition(24, 48);
    rl.setTargetFPS(self.fps());
    const render_texture = try rl.loadRenderTexture(screen_x, screen_y);
    self.addSingleton(render_texture);
}

fn createCamera(self: *Game) void {
    self.addSingleton(Game.Camera{
        .offset = .zero(),
        .target = .zero(),
        .rotation = 0,
        .zoom = self.zoom(),
    });
}

fn initAssets(self: *Game, comptime options: Game.Assets.InitOptions) void {
    self.addSingleton(Game.Assets.init(self.allocator, options));
}

fn createSystems(self: *Game) void {
    self.addSingleton(Game.S.Animation.init());
    self.addSingleton(Game.S.Camera.init());
    self.addSingleton(Game.S.Controllable.init());
    self.addSingleton(Game.S.DestroyEntities.init());
    self.addSingleton(Game.S.Input.init());
    self.addSingleton(Game.S.Physics.init());
    self.addSingleton(Game.S.RelativePosition.init());
}
