const std = @import("std");
const Game = @import("game.zig").Game;
const rl = @import("raylib");

const enable_debug_draw = true;

pub fn draw(self: *Game) void {
    rl.clearBackground(.black);
    self.camera().begin();
    drawRenderables(self);
    self.camera().end();
    rl.drawFPS(8, 8);

    var ui_camera = self.camera().*;
    ui_camera.offset = .zero();
    ui_camera.target = .zero();
    ui_camera.begin();
    debugDrawUI(self);
    ui_camera.end();
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
