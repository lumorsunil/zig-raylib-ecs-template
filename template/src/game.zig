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
    noise_cache: std.AutoHashMapUnmanaged(u64, L.PerlinNoise2D) = .empty,
    mode: L.Mode = .normal,
    screen_state: L.ScreenState = .gameplay,
    wants_to_quit: bool = false,

    pub const max_physics_frames = 1;

    pub const C = @import("components.zig");
    pub const S = @import("systems.zig");
    pub const L = @import("lib.zig");

    pub fn init(main_init: std.process.Init) @This() {
        return .{
            .io = main_init.io,
            .allocator = main_init.gpa,
            .reg = .init(main_init.gpa),
            .random_io = .{ .io = main_init.io },
        };
    }

    pub fn deinit(self: *@This()) void {
        self.noise_cache.deinit(self.allocator);
        const event = self.getSingleton(Game.S.Event);
        event.deinit();
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

    pub fn screenSize(self: @This()) L.Vector2 {
        return self.pixelSize() * L.V.scalar2(self.zoom());
    }

    pub fn pixelSize(_: @This()) L.Vector2 {
        return .{ 320, 256 };
    }

    pub fn worldSize(self: @This()) L.Vector2 {
        return self.pixelSize();
    }

    pub fn worldPos(_: @This()) L.Vector2 {
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

    pub const assets = singletonFn(L.Assets);
    pub const camera = singletonFn(L.Camera);
    pub const cameraSystem = singletonFn(Game.S.Camera);
    pub const input = singletonFn(Game.S.Input);
    pub const physics = singletonFn(Game.S.Physics);
    pub const controllable = singletonFn(Game.S.Controllable);
    pub const destroyEntitiesSystem = singletonFn(Game.S.DestroyEntities);

    pub fn createEntity(self: *@This(), ce: @import("component-enum.zig").CE) L.EntityContext {
        return @import("component-enum.zig").createCE(self, ce);
    }

    pub fn destroyEntity(self: *@This(), entity: ecs.Entity) void {
        const destroy_entities = self.getSingleton(Game.S.DestroyEntities);
        destroy_entities.destroy(entity);
    }

    pub fn getOneByTag(self: *@This(), comptime T: type) L.EntityContext {
        var it = self.entityIterator(.{T}, .{});
        return it.next().?;
    }

    pub fn tryGetOneByTag(self: *@This(), comptime T: type) ?L.EntityContext {
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

    pub fn entityIterator(
        self: *@This(),
        comptime includes: anytype,
        comptime excludes: anytype,
    ) L.EntityIterator(includes, excludes) {
        return .init(self, self.reg.view(includes, excludes));
    }

    pub fn forEach(
        self: *@This(),
        callback: fn (L.EntityContext) void,
        comptime includes: anytype,
        comptime excludes: anytype,
    ) void {
        var it = self.entityIterator(includes, excludes);
        while (it.next()) |ctx| callback(ctx);
    }

    pub fn random(self: *@This()) std.Random {
        return self.random_io.interface();
    }

    pub fn hitbox(_: *@This(), ctx: L.EntityContext) Game.L.Rectangle {
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
        ctx: L.EntityContext,
        animation: Game.C.Animation,
    ) void {
        ctx.add(animation);
        ctx.add(animation.getFrame());
    }

    /// Takes a world coord and returns a vector from [0,0] to [1,1]
    pub fn getRelativePosition(self: *@This(), abs_pos: Game.L.Vector2) Game.L.Vector2 {
        return abs_pos.subtract(self.worldPos()).divide(self.worldSize());
    }

    /// Takes a vector from [0,0] to [1,1] and returns a world coord
    pub fn getAbsolutePos(self: *@This(), rel_pos: Game.L.Vector2) Game.L.Vector2 {
        return rel_pos * self.worldSize() + self.worldPos();
    }

    pub fn getTexture(self: *@This(), key: L.Assets.TextureKey) ?L.Texture {
        const texture = self.assets().textures.load(.init(self), key) orelse return null;
        return texture.*;
    }

    pub fn getImage(self: *@This(), key: L.Assets.ImageKey) ?L.Image {
        const image = self.assets().images.load(.init(self), key) orelse return null;
        return image.*;
    }

    pub fn getSound(self: *@This(), key: L.Assets.SoundKey) ?L.Sound {
        const sound = self.assets().sounds.load(.init(self), key) orelse return null;
        return sound.*;
    }

    pub fn getMusic(self: *@This(), key: L.Assets.MusicKey) ?L.Music {
        const music = self.assets().musics.load(.init(self), key) orelse return null;
        return music.*;
    }

    pub fn getShader(self: *@This(), key: L.Assets.ShaderKey) ?L.Shader {
        const shader = self.assets().shaders.load(.init(self), key) orelse return null;
        return shader.*;
    }

    pub fn playSound(self: *@This(), key: L.Assets.SoundKey) void {
        const sound = self.getSound(key) orelse return;
        rl.playSound(sound);
    }

    pub fn isSoundPlaying(self: *@This(), key: L.Assets.SoundKey) bool {
        const sound = self.getSound(key) orelse return false;
        return rl.isSoundPlaying(sound);
    }

    pub fn setSoundPitch(self: *@This(), key: L.Assets.SoundKey, pitch: f32) void {
        const sound = self.getSound(key) orelse return;
        rl.setSoundPitch(sound, pitch);
    }

    pub fn setSoundVolume(self: *@This(), key: L.Assets.SoundKey, volume: f32) void {
        const sound = self.getSound(key) orelse return;
        rl.setSoundVolume(sound, volume);
    }

    pub fn playMusic(self: *@This(), key: L.Assets.MusicKey) void {
        const music = self.getMusic(key) orelse return;
        rl.playMusicStream(music);
        self.music = music;
    }

    pub fn beginShaderMode(self: *@This(), key: L.Assets.ShaderKey) void {
        const shader = self.getShader(key) orelse return;
        rl.beginShaderMode(shader);
    }

    pub fn endShaderMode(_: *@This()) void {
        rl.endShaderMode();
    }

    pub fn setShaderValue(
        self: *@This(),
        key: L.Assets.ShaderKey,
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
        } else if (T == L.Vector2) {
            rl.setShaderValue(shader, loc, &value, .vec2);
        } else if (T == L.Vector3) {
            rl.setShaderValue(shader, loc, &value, .vec3);
        } else if (T == L.Vector4) {
            rl.setShaderValue(shader, loc, &value, .vec4);
        } else if (T == L.Color) {
            rl.setShaderValue(shader, loc, &.{ value.r, value.g, value.b, value.a }, .vec4);
        } else if (T == bool) {
            rl.setShaderValue(shader, loc, &@intFromBool(value), .int);
        } else if (T == L.Texture) {
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

    pub fn getRandomEntity(
        self: *Game,
        comptime includes: anytype,
        comptime excludes: anytype,
    ) ?Game.L.EntityContext {
        var len: usize = 0;
        var it = self.entityIterator(includes, excludes);
        while (it.next()) |_| len += 1;
        const r = self.random().uintLessThan(usize, len);
        it.reset();
        for (0..r) |_| _ = it.next();
        return it.next();
    }

    pub fn chance(self: *Game, chance_: f32) bool {
        return self.random().float(f32) <= chance_;
    }

    const NoiseOptions = struct {
        seed: u64 = 0,
    };

    pub fn noiseInit(self: *Game, options: NoiseOptions) L.PerlinNoise2D {
        if (!self.noise_cache.contains(options.seed)) {
            self.noise_cache.put(self.allocator, options.seed, .init(options.seed)) catch unreachable;
        }

        return self.noise_cache.get(options.seed).?;
    }

    pub fn noise(self: *Game, v: L.Vector2, options: NoiseOptions) f32 {
        const noise_ = self.noiseInit(options);
        const x, const y = v;
        return noise_.noise(x, y);
    }

    pub const standard_sprite_size = L.Vector2{ 16, 16 };

    pub const SpriteOptions = struct {
        size: L.Vector2 = standard_sprite_size,
        texture: L.Assets.TextureKey,
    };

    pub fn sprite(self: *Game, offset: L.Vector2, options: SpriteOptions) Game.C.Renderable {
        const texture = self.getTexture(options.texture) orelse unreachable;
        return .initSprite(texture, L.Rectangle.init(offset, options.size));
    }

    pub fn on(
        self: *Game,
        event_type: Game.C.Event.EntityEventTag,
        listener: Game.S.Event.EntityEventListener,
    ) void {
        const event = self.getSingleton(Game.S.Event);
        event.on(event_type, listener);
    }

    pub fn off(
        self: *Game,
        event_type: Game.C.Event.EntityEventTag,
        listener: Game.S.Event.EntityEventListener,
    ) void {
        const event = self.getSingleton(Game.S.Event);
        event.off(event_type, listener);
    }
};
