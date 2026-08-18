const Game = @import("game.zig").Game;
const rl = @import("raylib");

pub fn setupRaylib(game: *Game) !void {
    const screen_size = game.screenSize();
    const screen_x, const screen_y = Game.L.V.toInt(i32, screen_size);
    // const screen_x: i32 = @intFromFloat(screen_size.x);
    // const screen_y: i32 = @intFromFloat(screen_size.y);
    rl.initWindow(screen_x, screen_y, "Game Template");
    rl.setWindowPosition(24, 48);
    rl.setTargetFPS(game.fps());
    rl.initAudioDevice();
    rl.setMasterVolume(0.3);
    const render_buffer = try Game.L.RenderBuffer.init(screen_size);
    game.addSingleton(render_buffer);
}
