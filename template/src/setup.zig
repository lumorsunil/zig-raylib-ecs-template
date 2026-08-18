const std = @import("std");
const Game = @import("game.zig").Game;
const rl = @import("raylib");

pub fn setup(self: *Game) !void {
    try @import("setup-raylib.zig").setupRaylib(self);

    createCamera(self);
    initAssets(self, .load_all);

    @import("setup-systems.zig").setupSystems(self);
    setupSystems(self);
    try @import("preset.zig").Preset.demo_mod.createDemo(self);

    self.elapsed_time = self.elapsedRealTime();
}

fn createCamera(self: *Game) void {
    self.addSingleton(Game.L.Camera{
        .offset = .zero(),
        .target = .zero(),
        .rotation = 0,
        .zoom = self.zoom(),
    });
}

fn initAssets(self: *Game, comptime options: Game.L.Assets.InitOptions) void {
    self.addSingleton(Game.L.Assets.init(.init(self), options));
}

fn setupSystems(game: *Game) void {
    inline for (comptime std.meta.declarations(Game.S)) |decl| {
        const System = @field(Game.S, decl.name);

        if (std.meta.hasMethod(System, "setup")) {
            const system = game.getSingleton(System);
            system.setup(game);
        }
    }
}
