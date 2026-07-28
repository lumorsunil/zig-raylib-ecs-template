const std = @import("std");
const Game = @import("game.zig").Game;
const rl = @import("raylib");

const enable_debug_draw = true;

pub fn draw(self: *Game) void {
    const render_buffer = self.getSingleton(Game.RenderBuffer);
    rl.beginTextureMode(render_buffer.render_texture_a);

    rl.clearBackground(.black);
    self.camera().begin();
    drawBg(self);
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

    const screen_size = self.screenSize();

    // rl.beginTextureMode(render_buffer.render_texture_b);
    //
    // self.beginShaderMode(.god_rays);
    //
    // rl.drawTextureRec(
    //     render_buffer.render_texture_a.texture,
    //     .init(0, 0, screen_size.x, -screen_size.y),
    //     .init(0, 0),
    //     .white,
    // );
    //
    // self.endShaderMode();
    //
    // rl.endTextureMode();

    rl.beginDrawing();

    self.beginShaderMode(.crt);

    rl.drawTextureRec(
        render_buffer.render_texture_a.texture,
        Game.Rectangle.init(.{ 0, 0 }, screen_size * Game.V.v2(1, -1)).toRl(),
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
        const position = body.position();

        drawText("{}", .{position[0]}, .{ 8, 8 + 10 });
        drawText("{}", .{position[1]}, .{ 8, 8 + 20 });
    }
}

fn drawText(comptime fmt: []const u8, args: anytype, position: Game.Vector2) void {
    var buffer: [256]u8 = undefined;
    const text = std.fmt.bufPrintZ(&buffer, fmt, args) catch unreachable;
    const x, const y = Game.V.toInt(i32, position);
    rl.drawText(text, x, y, 8, .green);
}

fn drawRenderables(self: *Game) void {
    self.forEach(
        drawRenderable,
        .{ Game.C.Renderable, Game.C.Body },
        .{Game.C.Invisible},
    );
}

fn drawRenderable(ctx: Game.EntityContext) void {
    const body = ctx.get(Game.C.Body);
    const renderable = ctx.get(Game.C.Renderable);

    const has_shader = beginRenderableShader(ctx);

    renderable.draw(body.position(), body.rotation());

    if (has_shader) {
        ctx.game.endShaderMode();
    }
}

fn beginRenderableShader(ctx: Game.EntityContext) bool {
    if (ctx.tryGetConst(Game.Assets.ShaderKey)) |shader| {
        ctx.game.beginShaderMode(shader);
        if (ctx.tryGet(Game.C.PrepareShader)) |prepare_shader| {
            prepare_shader.prepare(ctx, shader);
        }

        return true;
    }

    return false;
}

fn drawBg(self: *Game) void {
    const texture = self.getTexture(.bg) orelse return;
    rl.drawTextureV(texture, .init(0, 0), .white);
}

fn drawGrid(self: *Game) void {
    const grid = self.physics().grid orelse return;

    for (0..grid.width) |x| {
        for (0..grid.height) |y| {
            if (!grid.isSolid(self, x, y)) continue;

            const size = grid.cellSize();
            const position = Game.V.v2(x, y) * size;
            rl.drawRectangleV(Game.V.toRl(position), Game.V.toRl(size), .light_gray);
        }
    }
}
