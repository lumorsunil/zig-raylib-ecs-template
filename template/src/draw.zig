const std = @import("std");
const Game = @import("game.zig").Game;
const rl = @import("raylib");

const enable_debug_draw = true;

pub fn draw(self: *Game) void {
    const render_texture = self.getSingleton(rl.RenderTexture2D).*;
    rl.beginTextureMode(render_texture);

    rl.clearBackground(.black);
    self.camera().begin();
    drawGrid(self);
    drawRenderables(self);
    self.camera().end();
    rl.drawFPS(8, 8);

    var ui_camera = self.camera().*;
    ui_camera.offset = .zero();
    ui_camera.target = .zero();
    ui_camera.begin();
    debugDrawUI(self);
    ui_camera.end();

    rl.endTextureMode();

    rl.beginDrawing();

    self.beginShaderMode(.crt);

    const screen_size = self.screenSize();
    rl.drawTextureRec(
        render_texture.texture,
        .init(0, 0, screen_size.x, -screen_size.y),
        .init(0, 0),
        .white,
    );

    self.endShaderMode();

    rl.endDrawing();
}

fn debugDrawUI(self: *Game) void {
    if (!enable_debug_draw) return;

    var it = self.entityIterator(.{ Game.C.Body, Game.C.Controllable }, .{});

    while (it.next()) |ctx| {
        const body = ctx.getConst(Game.C.Body);

        drawText("{}", .{body.position.x}, .init(8, 8 + 10));
        drawText("{}", .{body.position.y}, .init(8, 8 + 20));
    }
}

fn drawText(comptime fmt: []const u8, args: anytype, position: Game.Vector) void {
    var buffer: [256]u8 = undefined;
    const text = std.fmt.bufPrintZ(&buffer, fmt, args) catch unreachable;
    rl.drawText(text, @intFromFloat(position.x), @intFromFloat(position.y), 8, .green);
}

fn drawRenderables(self: *Game) void {
    var it = self.entityIterator(.{ Game.C.Renderable, Game.C.Body }, .{Game.C.Invisible});

    while (it.next()) |ctx| {
        const body = ctx.get(Game.C.Body);
        const renderable = ctx.get(Game.C.Renderable);

        renderable.draw(body.position, body.rotation);
    }
}

fn drawGrid(self: *Game) void {
    const grid = self.physics().grid orelse return;

    for (0..grid.width) |x| {
        for (0..grid.height) |y| {
            if (!grid.isSolid(self, x, y)) continue;

            const size = grid.cellSize();
            const position = Game.Vector.init(
                @floatFromInt(x),
                @floatFromInt(y),
            ).multiply(size);
            rl.drawRectangleV(position, size, .light_gray);
        }
    }
}
