const Game = @import("../game.zig").Game;

pub const PrepareShader = struct {
    prepareFn: *const fn (Game.EntityContext, shader: Game.Shader) void,

    pub fn init(
        prepareFn: *const fn (Game.EntityContext, shader: Game.Shader) void,
    ) @This() {
        return .{ .prepareFn = prepareFn };
    }

    pub fn prepare(
        self: PrepareShader,
        ctx: Game.EntityContext,
        shader_key: Game.Assets.ShaderKey,
    ) void {
        const shader = ctx.game.getShader(shader_key) orelse return;
        self.prepareFn(ctx, shader);
    }
};
