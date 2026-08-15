const std = @import("std");
const Game = @import("game.zig").Game;

pub const CE = struct {
    animation: ?Game.C.Animation = null,
    body: ?BodyInit = null,
    controllable: ?Game.C.Controllable = null,
    destroy_at: ?Game.C.DestroyAt = null,
    hitbox: ?Game.C.Hitbox = null,
    invisible: ?Game.C.Invisible = null,
    prepare_shader: ?Game.C.PrepareShader = null,
    relative_position: ?Game.C.RelativePosition = null,
    renderable: ?RenderableInit = null,

    pub fn merge(source: CE, overrides: CE) @This() {
        var result = source;

        inline for (std.meta.fields(CE)) |field| {
            if (@field(overrides, field.name)) |c| {
                @field(result, field.name) = c;
            }
        }

        return result;
    }
};

pub const BodyInit = struct {
    position: Game.Vector2,
    size: Game.Vector2,

    pub fn init(position: Game.Vector2, size: Game.Vector2) @This() {
        return .{ .position = position, .size = size };
    }

    pub fn add(self: @This(), ctx: Game.EntityContext) void {
        _ = ctx.addBody(self.position, self.size);
    }
};

pub const RenderableInit = union(enum) {
    from_animation,
    component_: Game.C.Renderable,

    pub fn init(renderable: Game.C.Renderable) @This() {
        return .{ .component_ = renderable };
    }

    pub fn add(self: @This(), ctx: Game.EntityContext) void {
        _ = self;
        _ = ctx;
    }

    pub fn post(self: @This(), ctx: Game.EntityContext) void {
        switch (self) {
            .from_animation => {
                const animation = ctx.get(Game.C.Animation);
                ctx.add(animation.getFrame());
            },
            .component_ => |c| ctx.add(c),
        }
    }
};

pub fn addCE(ctx: Game.EntityContext, ce: CE) void {
    inline for (std.meta.fields(CE)) |field| {
        if (@field(ce, field.name)) |c| {
            if (@hasDecl(@TypeOf(c), "add")) {
                c.add(ctx);
            } else {
                ctx.add(c);
            }
        }
    }

    inline for (std.meta.fields(CE)) |field| {
        if (@field(ce, field.name)) |c| {
            if (@hasDecl(@TypeOf(c), "post")) {
                c.post(ctx);
            }
        }
    }
}

pub fn createCE(game: *Game, ce: CE) Game.EntityContext {
    const ctx = Game.EntityContext.init(game, game.reg.create());
    addCE(ctx, ce);
    return ctx;
}
