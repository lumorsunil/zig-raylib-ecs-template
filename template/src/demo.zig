const Game = @import("game.zig").Game;
const rl = @import("raylib");

pub fn createDemo(game: *Game) !void {
    try createDefaultGrid(game);
    createPlayer(game);
    try createAnimatedSineThing(game);
    setupShader(game);
}

fn createPlayer(game: *Game) void {
    const player = game.createEntity();
    player.add(Game.C.Renderable.initRectangle(.init(16, 16), .white));
    _ = player.addBody(.init(150, 128), .init(16, 16));
    player.add(Game.C.Controllable.init());
    player.add(Game.Assets.ShaderKey.sobel);
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
            0 => .initRectangle(.init(10, 10), color),
            1 => .initCircle(5, color),
            2 => .initTriangle(.init(0, 0), .init(0, 10), .init(10, 10), color),
            else => unreachable,
        };
        frames[i] = .init(renderable, 1);
    }

    const ctx = game.createEntity();
    game.addAnimationAndRenderable(ctx, .init(.init(frames, 0.3), true));
    _ = ctx.addBody(game.getAbsolutePos(.init(0.8, 0.2)), .init(10, 10));
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

fn setupShader(self: *Game) void {
    setupCrtShader(self);
    // setupGodRaysShader(self);
}

fn setupCrtShader(self: *Game) void {
    const screen_size = self.screenSize();
    self.setShaderValue(.crt, "renderWidth", screen_size.x);
    self.setShaderValue(.crt, "renderHeight", screen_size.y);
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
