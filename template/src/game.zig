const std = @import("std");
const ecs = @import("ecs");
const rl = @import("raylib");
const emscripten = std.os.emscripten;

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
    mode: Mode = .normal,
    screen_state: ScreenState = .menu,
    wants_to_quit: bool = false,

    pub const max_physics_frames = 1;
    pub const Preset = @import("preset.zig").Preset;

    const Mode = enum { normal, debug };

    pub const ScreenState = union(enum) {
        menu,
        gameplay,
        game_over,
        ending,
    };

    pub const ztracy = @import("ztracy");

    pub const ZoneCtx = struct {
        ctx: ztracy.ZoneCtx,

        pub fn init(ctx: ztracy.ZoneCtx) @This() {
            return .{ .ctx = ctx };
        }

        pub fn end(self: @This()) void {
            self.ctx.End();
        }
    };

    pub fn tracyZoneN(comptime src: std.builtin.SourceLocation, label: [*:0]const u8) ZoneCtx {
        return .init(ztracy.ZoneN(src, label));
    }

    pub fn tracyZoneNC(
        comptime src: std.builtin.SourceLocation,
        label: [*:0]const u8,
        color: Color,
    ) ZoneCtx {
        return .init(ztracy.ZoneNC(src, label, @bitCast(color.toInt())));
    }

    pub const Assets = @import("assets.zig").Assets;

    pub const vector_mod = @import("vector.zig");
    pub const V = vector_mod.V;
    pub const Vector2 = vector_mod.Vector2;
    pub const Vector3 = vector_mod.Vector3;
    pub const Vector4 = vector_mod.Vector4;
    pub const Rectangle = @import("rectangle.zig").Rectangle;

    pub const Camera = rl.Camera2D;
    // pub const Vector2 = rl.Vector2;
    pub const Color = rl.Color;
    pub const Texture = rl.Texture2D;
    pub const Sound = rl.Sound;
    pub const Music = rl.Music;
    pub const Shader = rl.Shader;
    pub const RenderBuffer = @import("render-buffer.zig").RenderBuffer;

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
        rl.closeAudioDevice();
        rl.closeWindow();
    }

    var emscripten_game_ptr: *Game = undefined;

    pub fn run(self: *@This()) void {
        if (@import("builtin").cpu.arch.isWasm()) {
            emscripten_game_ptr = self;
            emscripten.emscripten_set_main_loop(emscripten_loop, 0, 1);
        } else {
            while (!rl.windowShouldClose() and !self.wants_to_quit) self.loop();
        }
    }

    fn emscripten_loop() callconv(.c) void {
        loop(emscripten_game_ptr);
    }

    fn loop(self: *@This()) void {
        self.update();
        self.draw();
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

    pub fn screenSize(self: @This()) Vector2 {
        return self.pixelSize() * V.scalar2(self.zoom());
    }

    pub fn pixelSize(_: @This()) Vector2 {
        return .{ 320, 256 };
    }

    pub fn worldSize(self: @This()) Vector2 {
        return self.pixelSize();
    }

    pub fn worldPos(_: @This()) Vector2 {
        return .{ 0, 0 };
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

    pub fn getOneByTagComponent(self: *@This(), comptime T: type) *T {
        var it = self.entityIterator(.{T}, .{});
        return it.next().?.get(T);
    }

    pub fn tryGetOneByTagComponent(self: *@This(), comptime T: type) ?*T {
        var it = self.entityIterator(.{T}, .{});
        const ctx = it.next() orelse return null;
        return ctx.tryGet(T);
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

        pub fn addBody(self: @This(), position: Vector2, size: Vector2) *Game.C.Body {
            const body = Game.C.Body.init(self, position, size);
            self.add(body);
            return self.get(Game.C.Body);
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

    pub fn forEach(
        self: *@This(),
        callback: fn (EntityContext) void,
        comptime includes: anytype,
        comptime excludes: anytype,
    ) void {
        var it = self.entityIterator(includes, excludes);
        while (it.next()) |ctx| callback(ctx);
    }

    pub fn random(self: *@This()) std.Random {
        return self.random_io.interface();
    }

    pub fn hitbox(_: *@This(), ctx: EntityContext) Game.C.Hitbox {
        const body = ctx.get(Game.C.Body);
        return .init(body.position(), body.size());
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
    pub fn getRelativePosition(self: *@This(), abs_pos: Game.Vector2) Game.Vector2 {
        return abs_pos.subtract(self.worldPos()).divide(self.worldSize());
    }

    /// Takes a vector from [0,0] to [1,1] and returns a world coord
    pub fn getAbsolutePos(self: *@This(), rel_pos: Game.Vector2) Game.Vector2 {
        return rel_pos * self.worldSize() + self.worldPos();
    }

    pub fn getTexture(self: *@This(), key: Assets.TextureKey) ?Texture {
        const texture = self.assets().textures.load(.init(self), key) orelse return null;
        return texture.*;
    }

    pub fn getSound(self: *@This(), key: Assets.SoundKey) ?Sound {
        const sound = self.assets().sounds.load(.init(self), key) orelse return null;
        return sound.*;
    }

    pub fn getMusic(self: *@This(), key: Assets.MusicKey) ?Music {
        const music = self.assets().musics.load(.init(self), key) orelse return null;
        return music.*;
    }

    pub fn getShader(self: *@This(), key: Assets.ShaderKey) ?Shader {
        const shader = self.assets().shaders.load(.init(self), key) orelse return null;
        return shader.*;
    }

    pub fn playSound(self: *@This(), key: Assets.SoundKey) void {
        const sound = self.getSound(key) orelse return;
        rl.playSound(sound);
    }

    pub fn isSoundPlaying(self: *@This(), key: Assets.SoundKey) bool {
        const sound = self.getSound(key) orelse return false;
        return rl.isSoundPlaying(sound);
    }

    pub fn setSoundPitch(self: *@This(), key: Assets.SoundKey, pitch: f32) void {
        const sound = self.getSound(key) orelse return;
        rl.setSoundPitch(sound, pitch);
    }

    pub fn setSoundVolume(self: *@This(), key: Assets.SoundKey, volume: f32) void {
        const sound = self.getSound(key) orelse return;
        rl.setSoundVolume(sound, volume);
    }

    pub fn playMusic(self: *@This(), key: Assets.MusicKey) void {
        const music = self.getMusic(key) orelse return;
        rl.playMusicStream(music);
        self.music = music;
    }

    pub fn beginShaderMode(self: *@This(), key: Assets.ShaderKey) void {
        const shader = self.getShader(key) orelse return;
        rl.beginShaderMode(shader);
    }

    pub fn endShaderMode(_: *@This()) void {
        rl.endShaderMode();
    }

    pub fn setShaderValue(
        self: *@This(),
        key: Assets.ShaderKey,
        identifier: [:0]const u8,
        value: anytype,
    ) void {
        const shader = self.getShader(key) orelse return;
        const loc = rl.getShaderLocation(shader, identifier);
        const T = @TypeOf(value);

        if (T == usize) {
            rl.setShaderValue(shader, loc, &value, .int);
        } else if (T == f32 or T == comptime_float or T == f64 or T == comptime_int) {
            const float_value: f32 = value;
            rl.setShaderValue(shader, loc, &float_value, .float);
        } else if (T == Vector2) {
            rl.setShaderValue(shader, loc, &value, .vec2);
        } else if (T == Vector3) {
            rl.setShaderValue(shader, loc, &value, .vec3);
        } else if (T == Vector4) {
            rl.setShaderValue(shader, loc, &value, .vec4);
        } else if (T == Color) {
            rl.setShaderValue(shader, loc, &.{ value.r, value.g, value.b, value.a }, .vec4);
        } else if (T == bool) {
            rl.setShaderValue(shader, loc, &@intFromBool(value), .int);
        } else if (T == Texture) {
            rl.setShaderValueTexture(shader, loc, value);
        } else if (@typeInfo(T) == .array) {
            const uniform_type = switch (@typeInfo(T).array.len) {
                1 => .float,
                2 => .vec2,
                3 => .vec3,
                4 => .vec4,
                else => unreachable,
            };
            rl.setShaderValue(shader, loc, &value, uniform_type);
        }
    }
};
