const rl = @import("raylib");
const Game = @import("game.zig").Game;

pub const RenderBuffer = struct {
    render_texture_a: rl.RenderTexture,
    render_texture_b: rl.RenderTexture,

    pub fn init(screen_size: Game.L.Vector2) !@This() {
        const width, const height = Game.L.V.toInt(i32, screen_size);

        return .{
            .render_texture_a = try rl.loadRenderTexture(width, height),
            .render_texture_b = try rl.loadRenderTexture(width, height),
        };
    }
};
