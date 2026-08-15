const std = @import("std");
const Game = @import("game.zig").Game;
const rl = @import("raylib");

pub fn setup(self: *Game) !void {
    try @import("setup-raylib.zig").setupRaylib(self);

    createCamera(self);
    initAssets(self, .load_all);

    @import("setup-systems.zig").setupSystems(self);
    try @import("preset.zig").Preset.demo_mod.createDemo(self);

    self.elapsed_time = self.elapsedRealTime();
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
    self.addSingleton(Game.Assets.init(.init(self), options));
}
