const std = @import("std");
const ecs = @import("ecs");
const rl = @import("raylib");

pub const Game = struct {
    io: std.Io,
    allocator: std.mem.Allocator,
    reg: ecs.Registry,
    random_io: std.Random.IoSource,
    elapsed_time: f64 = 0,
    delta_time: f32 = 0,
    physics_frames: usize = 0,
    rem_time: f32 = 0,
    is_paused: bool = false,
    music: ?rl.Music = null,

    pub const max_physics_frames = 1;
    pub const Preset = @import("preset.zig").Preset;

    pub const Assets = @import("assets.zig").Assets;

    pub const Camera = rl.Camera2D;
    pub const Vector = rl.Vector2;
    pub const Color = rl.Color;
    pub const Texture = rl.Texture2D;

    pub const C = @import("components.zig");
    pub const S = @import("systems.zig");

    pub fn init(main_init: std.process.Init) @This() {
        return .{
            .io = main_init.io,
            .allocator = main_init.gpa,
            .reg = .init(main_init.gpa),
            .random_io = .{ .io = main_init.io },
        };
    }

    pub fn deinit(self: *@This()) void {
        self.physics().deinit(self.allocator);
        self.reg.deinit();
        rl.closeWindow();
    }

    pub fn run(self: *@This()) void {
        while (!rl.windowShouldClose()) {
            self.update();
            self.draw();
        }
    }

    pub const setup = @import("setup.zig").setup;
    pub const update = @import("update.zig").update;
    pub const draw = @import("draw.zig").draw;

    pub fn zoom(_: @This()) f32 {
        return 4;
    }

    pub fn fps(_: @This()) u8 {
        return 60;
    }

    pub fn physicsFps(_: @This()) u8 {
        return 60;
    }

    pub fn elapsedTime(self: @This()) f64 {
        return self.elapsed_time;
    }

    pub fn elapsedRealTime(_: @This()) f64 {
        return rl.getTime();
    }

    pub fn deltaTime(self: @This()) f32 {
        return self.delta_time;
    }

    pub fn deltaRealTime(_: @This()) f32 {
        return rl.getFrameTime();
    }

    pub fn physicsTimeStep(self: @This()) f32 {
        return 1.0 / @as(f32, self.physicsFps());
    }

    pub fn screenSize(self: @This()) Vector {
        return self.pixelSize().scale(self.zoom());
    }

    pub fn pixelSize(_: @This()) Vector {
        return .init(320, 256);
    }

    pub fn worldSize(self: @This()) Vector {
        return self.pixelSize();
    }

    pub fn worldPos(_: @This()) Vector {
        return .init(0, 0);
    }

    pub fn addSingleton(self: *@This(), singleton: anytype) void {
        self.reg.singletons().add(singleton);
    }

    pub fn getSingleton(self: *@This(), comptime T: type) *T {
        return self.reg.singletons().get(T);
    }

    fn singletonFn(comptime T: type) fn (*Game) *T {
        return struct {
            pub fn get(self: *Game) *T {
                return self.getSingleton(T);
            }
        }.get;
    }

    pub const assets = singletonFn(Assets);
    pub const camera = singletonFn(Camera);
    pub const cameraSystem = singletonFn(Game.S.Camera);
    pub const input = singletonFn(Game.S.Input);
    pub const physics = singletonFn(Game.S.Physics);
    pub const controllable = singletonFn(Game.S.Controllable);
    pub const destroyEntitiesSystem = singletonFn(Game.S.DestroyEntities);

    pub fn createEntity(self: *@This()) EntityContext {
        return .init(self, self.reg.create());
    }

    pub fn destroyEntity(self: *@This(), entity: ecs.Entity) void {
        const destroy_entities = self.getSingleton(Game.S.DestroyEntities);
        destroy_entities.destroy(entity);
    }

    pub fn getOneByTag(self: *@This(), comptime T: type) EntityContext {
        var it = self.entityIterator(.{T}, .{});
        return it.next().?;
    }

    pub fn tryGetOneByTag(self: *@This(), comptime T: type) ?EntityContext {
        var it = self.entityIterator(.{T}, .{});
        return it.next();
    }

    pub const EntityContext = struct {
        game: *Game,
        entity: ecs.Entity,

        pub fn init(game: *Game, entity: ecs.Entity) @This() {
            return .{ .game = game, .entity = entity };
        }

        pub fn has(self: EntityContext, comptime T: type) bool {
            return self.game.reg.has(T, self.entity);
        }

        pub fn get(self: EntityContext, comptime T: type) *T {
            return self.game.reg.get(T, self.entity);
        }

        pub fn getConst(self: EntityContext, comptime T: type) T {
            return self.game.reg.getConst(T, self.entity);
        }

        /// If the entry wasn't found, it is initialized with ```undefined```
        pub fn getOrAdd(self: EntityContext, comptime T: type) *T {
            // Own implementation since zig-ecs doesn't initialize
            // value to undefined, it tries to use default constructor
            // which makes some types impossible to use with the original getOrAdd
            if (self.tryGet(T)) |ptr| return ptr;
            self.add(@as(T, undefined));
            return self.get(T);
        }

        pub fn tryGet(self: EntityContext, comptime T: type) ?*T {
            return self.game.reg.tryGet(T, self.entity);
        }

        pub fn tryGetConst(self: EntityContext, comptime T: type) ?T {
            return self.game.reg.tryGetConst(T, self.entity);
        }

        pub fn add(self: EntityContext, component: anytype) void {
            return self.game.reg.addOrReplace(self.entity, component);
        }

        pub fn remove(self: EntityContext, comptime T: type) void {
            return self.game.reg.removeIfExists(T, self.entity);
        }

        pub fn destroy(self: EntityContext) void {
            self.game.destroyEntity(self.entity);
        }

        pub fn valid(self: EntityContext) bool {
            return self.game.reg.valid(self.entity);
        }
    };

    fn EntityIterator(comptime includes: anytype, comptime excludes: anytype) type {
        const View, const Iterator = comptime brk: {
            if (includes.len == 1 and excludes.len == 0) break :brk .{ ecs.BasicView(includes[0]), ecs.utils.ReverseSliceIterator(ecs.Entity) };
            break :brk .{ ecs.MultiView(includes, excludes), ecs.MultiView(includes, excludes).Iterator };
        };

        return struct {
            game: *Game,
            view: View,
            it: ?Iterator = null,

            pub fn init(game: *Game, view: View) @This() {
                return .{ .game = game, .view = view };
            }

            pub fn next(self: *@This()) ?EntityContext {
                const it = self.getIt();
                const entity = it.next() orelse return null;
                return .init(self.game, entity);
            }

            pub fn reset(self: *@This()) void {
                const it = self.getIt();
                it.reset();
            }

            fn getIt(self: *@This()) *Iterator {
                if (self.it) |*it| return it;
                self.it = self.view.entityIterator();
                return &(self.it.?);
            }
        };
    }

    pub fn entityIterator(
        self: *@This(),
        comptime includes: anytype,
        comptime excludes: anytype,
    ) EntityIterator(includes, excludes) {
        return .init(self, self.reg.view(includes, excludes));
    }

    pub fn random(self: *@This()) std.Random {
        return self.random_io.interface();
    }

    pub fn hitbox(_: *@This(), ctx: EntityContext) Game.C.Hitbox {
        const body = ctx.get(Game.C.Body);
        var hitbox_component = ctx.tryGetConst(Game.C.Hitbox) orelse {
            const renderable = ctx.get(Game.C.Renderable);
            const size = renderable.size(body.rotation);

            return .init(body.position, size);
        };

        hitbox_component.setPosition(body.position.add(hitbox_component.position()));

        return hitbox_component;
    }

    pub fn pauseTime(self: *@This()) void {
        self.is_paused = true;
    }

    pub fn unpauseTime(self: *@This()) void {
        self.is_paused = false;
    }

    pub fn updateTime(self: *@This()) void {
        if (self.is_paused) return;
        const time_step = self.physicsTimeStep();
        var dt = self.deltaRealTime();
        const f_last_physics_frames: f32 = @floatFromInt(self.physics_frames);
        self.elapsed_time += f_last_physics_frames * time_step;
        const f_desired_physics_frames: f32 = @divFloor(dt + self.rem_time, time_step);
        const f_physics_frames: f32 = @min(max_physics_frames, f_desired_physics_frames);
        const physics_delta_time = f_physics_frames * time_step;
        const f_desired_delta = f_desired_physics_frames - f_physics_frames;
        dt -= f_desired_delta * time_step;
        self.physics_frames = @intFromFloat(f_physics_frames);
        self.rem_time -= physics_delta_time - dt;
        self.delta_time = physics_delta_time;
    }

    pub fn addAnimationAndRenderable(
        _: *@This(),
        ctx: EntityContext,
        animation: Game.C.Animation,
    ) void {
        ctx.add(animation);
        ctx.add(animation.getFrame());
    }

    /// Takes a world coord and returns a vector from [0,0] to [1,1]
    pub fn getRelativePosition(self: *@This(), abs_pos: Game.Vector) Game.Vector {
        return abs_pos.subtract(self.worldPos()).divide(self.worldSize());
    }

    /// Takes a vector from [0,0] to [1,1] and returns a world coord
    pub fn getAbsolutePos(self: *@This(), rel_pos: Game.Vector) Game.Vector {
        return rel_pos.multiply(self.worldSize()).add(self.worldPos());
    }

    pub fn getTexture(self: *@This(), key: Assets.TextureKey) ?Texture {
        return self.assets().textures.load(self.allocator, key);
    }

    pub fn playSound(self: *@This(), key: Assets.SoundKey) void {
        const sound = self.assets().sounds.load(self.allocator, key) orelse return;
        rl.playSound(sound.*);
    }

    pub fn playMusic(self: *@This(), key: Assets.MusicKey) void {
        const music = self.assets().musics.load(self.allocator, key) orelse return;
        rl.playMusicStream(music.*);
        self.music = music.*;
    }

    pub fn beginShaderMode(self: *@This(), key: Assets.ShaderKey) void {
        const shader = self.assets().shaders.load(self.allocator, key) orelse return;
        rl.beginShaderMode(shader.*);
    }

    pub fn endShaderMode(_: *@This()) void {
        rl.endShaderMode();
    }
};
