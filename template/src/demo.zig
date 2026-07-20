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
    player.add(Game.C.Body.init(.init(150, 128)));
    player.add(Game.C.Controllable.init());
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
    ctx.add(Game.C.Body.init(game.getAbsolutePos(.init(0.8, 0.2))));
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
    const crt = self.assets().shaders.load(self.allocator, .crt) orelse return;
    const render_width_loc = rl.getShaderLocation(crt.*, "renderWidth");
    const render_height_loc = rl.getShaderLocation(crt.*, "renderHeight");
    const center_loc = rl.getShaderLocation(crt.*, "center");
    const screen_size = self.screenSize();
    const center = [_]f32{ screen_size.x / 2, screen_size.y / 2 };

    rl.setShaderValue(crt.*, render_width_loc, &screen_size.x, .float);
    rl.setShaderValue(crt.*, render_height_loc, &screen_size.y, .float);
    rl.setShaderValue(crt.*, center_loc, &center, .vec2);
}
