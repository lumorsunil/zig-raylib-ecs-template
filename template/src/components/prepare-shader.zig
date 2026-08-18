const Game = @import("../game.zig").Game;

pub const PrepareShader = struct {
    prepareFn: *const fn (Game.L.EntityContext, shader: Game.L.Shader) void,

    pub fn init(
        prepareFn: *const fn (Game.L.EntityContext, shader: Game.L.Shader) void,
    ) @This() {
        return .{ .prepareFn = prepareFn };
    }

    pub fn prepare(
        self: PrepareShader,
        ctx: Game.L.EntityContext,
        shader_key: Game.L.Assets.ShaderKey,
    ) void {
        const shader = ctx.game.getShader(shader_key) orelse return;
        self.prepareFn(ctx, shader);
    }
};
