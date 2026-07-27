const rl = @import("raylib");
const Game = @import("game.zig").Game;

pub const RenderBuffer = struct {
    render_texture_a: rl.RenderTexture,
    render_texture_b: rl.RenderTexture,

    pub fn init(screen_size: Game.Vector) !@This() {
        const width: i32 = @intFromFloat(screen_size.x);
        const height: i32 = @intFromFloat(screen_size.y);

        return .{
            .render_texture_a = try rl.loadRenderTexture(width, height),
            .render_texture_b = try rl.loadRenderTexture(width, height),
        };
    }
};
