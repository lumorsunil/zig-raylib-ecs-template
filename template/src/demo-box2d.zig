const Game = @import("game.zig").Game;
const rl = @import("raylib");
const createCE = @import("component-enum.zig").createCE;

pub fn createDemo(game: *Game) !void {
    createWorld(game);
    createPlayer(game);
    createGround(game);
    try createAnimatedSineThing(game);
    setupShader(game);
}

fn createWorld(game: *Game) void {
    var world_def = Game.b2.b2DefaultWorldDef();
    world_def.gravity = Game.V.toB2(@import("preset.zig").Preset.gravity);
    const world = Game.b2.b2CreateWorld(&world_def);
    game.addSingleton(world);
}

fn createPlayer(game: *Game) void {
    _ = game.createEntity(.{
        .renderable = .init(.initRectangle(.{ 16, 16 }, .white)),
        .body = .boxAuto(.{ 150, 128 }, .{ 16, 16 }, .{}),
        .controllable = .init(),
    });
}

fn createGround(game: *Game) void {
    const size = Game.V.v2(640, 16);

    _ = game.createEntity(.{
        .renderable = .init(.initRectangle(size, .white)),
        .body = .boxAuto(.{ 0, 160 }, size, .{ .is_dynamic = false }),
        .controllable = .init(),
    });
}

fn createAnimatedSineThing(game: *Game) !void {
    const frames = try game.allocator.alloc(Game.C.Animation.Frame, 6);
    for (0..frames.len) |i| {
        const color: Game.Color = switch (i) {
            0 => .red,
            1 => .blue,
            2 => .yellow,
            3 => .green,
            4 => .purple,
            5 => .pink,
            else => unreachable,
        };
        const renderable: Game.C.Renderable = switch (i % 3) {
            0 => .initRectangle(.{ 10, 10 }, color),
            1 => .initCircle(5, color),
            2 => .initTriangle(.{ 0, 0 }, .{ 0, 10 }, .{ 10, 10 }, color),
            else => unreachable,
        };
        frames[i] = .init(renderable, 1);
    }

    _ = game.createEntity(.{
        .animation = .init(.init(frames, 0.3), true),
        .renderable = .from_animation,
        .body = .boxAuto(game.getAbsolutePos(.{ 0.8, 0.2 }), .{ 10, 10 }, .{}),
    });
}

fn setupShader(self: *Game) void {
    setupCrtShader(self);
    // setupGodRaysShader(self);
}

fn setupCrtShader(self: *Game) void {
    const screen_size = self.screenSize();
    self.setShaderValue(.crt, "renderWidth", screen_size[0]);
    self.setShaderValue(.crt, "renderHeight", screen_size[1]);
    self.setShaderValue(.crt, "scanlineThick", 3.0);
    self.setShaderValue(.crt, "scanlineIntensity", 0.5);
    self.setShaderValue(.crt, "distortX", 0.03);
    self.setShaderValue(.crt, "distortY", 0.06);
}

fn setupGodRaysShader(self: *Game) void {
    const screen_size = self.screenSize();
    self.setShaderValue(.god_rays, "renderWidth", screen_size.x);
    self.setShaderValue(.god_rays, "renderHeight", screen_size.y);
}
