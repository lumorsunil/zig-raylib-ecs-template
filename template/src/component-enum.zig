const std = @import("std");
const Game = @import("game.zig").Game;

pub const CE = struct {
    animation: ?Game.C.Animation = null,
    body: ?BodyInit = null,
    controllable: ?Game.C.Controllable = null,
    destroy_at: ?Game.C.DestroyAt = null,
    event: ?Game.C.Event = null,
    invisible: ?Game.C.Invisible = null,
    prepare_shader: ?Game.C.PrepareShader = null,
    relative_position: ?Game.C.RelativePosition = null,
    renderable: ?RenderableInit = null,
    state_machine: ?StateMachineInit = null,

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

pub const BodyInit = union(enum) {
    empty,
    container_: struct {
        position: Game.L.Vector2,
        size: Game.L.Vector2,
        options: BodyInitOptions,
    },
    box2d_: struct {
        body_def: Game.L.b2.b2BodyDef,
        shape_def: Game.L.b2.b2ShapeDef,
        shape: Box2DShape,
    },

    pub const Box2DShape = union(enum) {
        polygon: Game.L.b2.b2Polygon,
        circle: Game.L.b2.b2Circle,
        segment: Game.L.b2.b2Segment,

        pub fn createShape(
            self: @This(),
            body: Game.L.b2.b2BodyId,
            shape_def: Game.L.b2.b2ShapeDef,
        ) Game.L.b2.b2ShapeId {
            return switch (self) {
                .polygon => |polygon| body.b2CreatePolygonShape(&shape_def, &polygon),
                .circle => |circle| body.b2CreateCircleShape(&shape_def, &circle),
                .segment => |segment| body.b2CreateSegmentShape(&shape_def, &segment),
            };
        }
    };

    pub const BodyInitOptions = struct {
        is_dynamic: bool = true,
    };

    pub fn boxAuto(
        position: Game.L.WorldVector,
        size: Game.L.WorldVector,
        options: BodyInitOptions,
    ) @This() {
        if (comptime @import("preset.zig").Preset.is_box2d) {
            const extent_x, const extent_y = size / Game.L.V.scalar2(2);

            var body_def = Game.L.b2.b2DefaultBodyDef();
            body_def.type = if (options.is_dynamic) Game.L.b2.b2_dynamicBody else Game.L.b2.b2_staticBody;
            body_def.position = Game.L.V.toB2(position);
            const shape_def = Game.L.b2.b2DefaultShapeDef();
            const shape = Box2DShape{
                .polygon = Game.L.b2.b2MakeBox(extent_x, extent_y),
            };

            return box2d(body_def, shape_def, shape);
        } else {
            return container(position, size, options);
        }
    }

    pub fn container(
        position: Game.L.WorldVector,
        size: Game.L.WorldVector,
        options: BodyInitOptions,
    ) @This() {
        return .{ .container_ = .{
            .position = position,
            .size = size,
            .options = options,
        } };
    }

    pub fn box2d(
        body_def: Game.L.b2.b2BodyDef,
        shape_def: Game.L.b2.b2ShapeDef,
        shape: Box2DShape,
    ) @This() {
        return .{ .box2d_ = .{
            .body_def = body_def,
            .shape_def = shape_def,
            .shape = shape,
        } };
    }

    pub fn add(self: @This(), ctx: Game.L.EntityContext) void {
        _ = ctx.addBody();

        switch (self) {
            .empty => {},
            .container_ => |container_| {
                if (comptime @import("preset.zig").Preset.is_box2d) return;
                ctx.game.physics().container.setBody(
                    ctx.entity.index,
                    container_.position,
                    .{ 0, 0 },
                    .{ 0, 0 },
                    0,
                    0,
                    container_.size,
                    !container_.options.is_dynamic,
                );
            },
            .box2d_ => |box2d_| {
                const world = ctx.game.getSingleton(Game.L.b2.b2WorldId);
                const body = world.b2CreateBody(&box2d_.body_def);
                _ = box2d_.shape.createShape(body, box2d_.shape_def);
                ctx.add(body);
            },
        }
    }
};

pub const RenderableInit = union(enum) {
    from_animation,
    component_: Game.C.Renderable,

    pub fn init(renderable: Game.C.Renderable) @This() {
        return .{ .component_ = renderable };
    }

    pub fn add(self: @This(), ctx: Game.L.EntityContext) void {
        _ = self;
        _ = ctx;
    }

    pub fn post(self: @This(), ctx: Game.L.EntityContext) void {
        switch (self) {
            .from_animation => {
                const animation = ctx.get(Game.C.Animation);
                ctx.add(animation.getFrame());
            },
            .component_ => |c| ctx.add(c),
        }
    }
};

pub const StateMachineInit = union(enum) {
    initial_state: *const Game.L.StateFunction,

    pub fn init(initial_state: *const Game.L.StateFunction) @This() {
        return .{ .initial_state = initial_state };
    }

    pub fn add(self: @This(), ctx: Game.L.EntityContext) void {
        ctx.add(Game.C.StateMachine.init());
        const sm = ctx.get(Game.C.StateMachine);
        sm.registerStateMachine(ctx.game.allocator, self.initial_state);
    }
};

pub fn addCE(ctx: Game.L.EntityContext, ce: CE) void {
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

pub fn createCE(game: *Game, ce: CE) Game.L.EntityContext {
    const ctx = Game.L.EntityContext.init(game, game.reg.create());
    addCE(ctx, ce);
    return ctx;
}
