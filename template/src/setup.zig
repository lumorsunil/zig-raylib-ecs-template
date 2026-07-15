const std = @import("std");
const Game = @import("game.zig").Game;
const rl = @import("raylib");

pub fn setup(self: *Game) !void {
    initRaylib(self);

    createCamera(self);
    initAssets(self, .load_all);
    createSystems(self);
    try @import("demo.zig").createDemo(self);
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

const InitAssetsOptions = enum {
    load_all,
    init_only,
};

fn initAssets(self: *Game, options: InitAssetsOptions) void {
    const textures, const sounds, const musics = brk: switch (options) {
        .load_all => {
            const textures = Game.Assets.loadAllTextures(self.allocator);
            const sounds = Game.Assets.loadAllSounds(self.allocator);
            const musics = Game.Assets.loadAllMusic(self.allocator);
            break :brk .{ textures, sounds, musics };
        },
        .init_only => {
            const textures = Game.Assets.Textures.empty;
            const sounds = Game.Assets.Sounds.empty;
            const musics = Game.Assets.Musics.empty;
            break :brk .{ textures, sounds, musics };
        },
    };

    self.addSingleton(textures);
    self.addSingleton(sounds);
    self.addSingleton(musics);
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
