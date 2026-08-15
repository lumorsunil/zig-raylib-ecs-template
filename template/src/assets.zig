const std = @import("std");
const Game = @import("game.zig").Game;
const Allocator = std.mem.Allocator;
const comptimePrint = std.fmt.comptimePrint;
const fmtJoin = std.fs.path.fmtJoin;
const rl = @import("raylib");

fn comptimePathJoin(comptime paths: []const []const u8) [:0]const u8 {
    return comptime comptimePrint("{f}", .{fmtJoin(paths)});
}

pub const LoadAssetContext = struct {
    io: std.Io,
    allocator: Allocator,

    pub fn init(game: *Game) @This() {
        return .{ .io = game.io, .allocator = game.allocator };
    }
};

pub fn AssetContainerOptions(comptime K: type, comptime V: type) type {
    return struct {
        keyToFilename: *const fn (K) [:0]const u8,
        load: *const fn (LoadAssetContext, filename: [:0]const u8) anyerror!V,
        unload: *const fn (V) void,
    };
}

pub fn AssetContainer(
    comptime K: type,
    comptime V: type,
    comptime options: AssetContainerOptions(K, V),
) type {
    return struct {
        map: std.hash_map.AutoHashMapUnmanaged(K, V) = .empty,

        pub const empty = init();

        pub fn init() @This() {
            return .{};
        }

        pub fn loadAll(self: *@This(), ctx: LoadAssetContext) void {
            inline for (std.meta.tags(K)) |tag| {
                _ = self.load(ctx, tag);
            }
        }

        pub fn keyToFilename(_: @This(), key: K) [:0]const u8 {
            return options.keyToFilename(key);
        }

        pub fn load(
            self: *@This(),
            ctx: LoadAssetContext,
            key: K,
        ) ?*V {
            return self.load_aux(ctx, key) catch |err| {
                const filename = self.keyToFilename(key);
                std.log.err("Could not load {s}: {}", .{ filename, err });
                return null;
            };
        }

        fn load_aux(self: *@This(), ctx: LoadAssetContext, key: K) !?*V {
            if (self.map.getPtr(key)) |value| return value;
            const filename = self.keyToFilename(key);
            const value: V = try options.load(ctx, filename);
            try self.map.put(ctx.allocator, key, value);
            return self.map.getPtr(key);
        }

        pub fn unload(self: *@This(), key: K) void {
            const value = self.map.get(key) orelse return;
            options.unload(value);
            _ = self.map.remove(key);
        }
    };
}

pub const Assets = struct {
    textures: Textures = .empty,
    images: Images = .empty,
    sounds: Sounds = .empty,
    musics: Musics = .empty,
    shaders: Shaders = .empty,

    pub const TextureKey = @import("assets-keys.zig").TextureKey;
    pub const ImageKey = @import("assets-keys.zig").ImageKey;
    pub const SoundKey = @import("assets-keys.zig").SoundKey;
    pub const MusicKey = @import("assets-keys.zig").MusicKey;
    pub const ShaderKey = @import("assets-keys.zig").ShaderKey;

    pub const Textures = AssetContainer(TextureKey, Game.Texture, .{
        .keyToFilename = textureKeyToFilename,
        .load = loadTexture,
        .unload = rl.unloadTexture,
    });
    fn loadTexture(_: LoadAssetContext, filename: [:0]const u8) !Game.Texture {
        return rl.loadTexture(filename);
    }

    pub const Images = AssetContainer(ImageKey, Game.Image, .{
        .keyToFilename = textureKeyToFilename,
        .load = loadImage,
        .unload = rl.unloadImage,
    });
    fn loadImage(_: LoadAssetContext, filename: [:0]const u8) !Game.Image {
        return rl.loadImage(filename);
    }

    pub const Sounds = AssetContainer(SoundKey, Game.Sound, .{
        .keyToFilename = soundKeyToFilename,
        .load = loadSound,
        .unload = rl.unloadSound,
    });
    fn loadSound(_: LoadAssetContext, filename: [:0]const u8) !Game.Sound {
        return rl.loadSound(filename);
    }

    pub const Musics = AssetContainer(MusicKey, Game.Music, .{
        .keyToFilename = musicKeyToFilename,
        .load = loadMusic,
        .unload = rl.unloadMusicStream,
    });
    fn loadMusic(_: LoadAssetContext, filename: [:0]const u8) !Game.Music {
        return rl.loadMusicStream(filename);
    }

    pub const Shaders = AssetContainer(ShaderKey, Game.Shader, .{
        .keyToFilename = shaderKeyToFilename,
        .load = loadShader,
        .unload = rl.unloadShader,
    });
    pub const LoadShaderError = error{InvalidFilename};
    fn loadShader(ctx: LoadAssetContext, filenames: [:0]const u8) !Game.Shader {
        const basename = std.fs.path.basename(filenames);
        const dirname = std.fs.path.dirname(filenames) orelse ".";
        var it = std.mem.splitScalar(u8, basename, ';');
        var vs_basename: ?[]const u8 = it.next() orelse return LoadShaderError.InvalidFilename;
        if (vs_basename.?.len == 0) vs_basename = null;
        var fs_basename: ?[]const u8 = it.next() orelse return LoadShaderError.InvalidFilename;
        if (fs_basename.?.len == 0) fs_basename = null;
        var vs_buffer: [1024]u8 = undefined;
        const vs = if (vs_basename) |bn| try std.fmt.bufPrint(&vs_buffer, "{f}", .{fmtJoin(&.{ dirname, bn })}) else null;
        var fs_buffer: [1024]u8 = undefined;
        const fs = if (fs_basename) |bn| try std.fmt.bufPrint(&fs_buffer, "{f}", .{fmtJoin(&.{ dirname, bn })}) else null;

        const vs_shader = if (vs) |filename| loadShaderFile(ctx, filename) catch |err| handleLoadShaderFileError(filename, err) else null;
        const fs_shader = if (fs) |filename| loadShaderFile(ctx, filename) catch |err| handleLoadShaderFileError(filename, err) else null;

        return rl.loadShaderFromMemory(vs_shader, fs_shader);
    }

    const shader_header = if (@import("builtin").cpu.arch.isWasm())
        \\#version 300 es
        \\
        \\precision mediump float;
        \\
    else
        \\#version 330
        \\
    ;

    fn loadShaderFile(ctx: LoadAssetContext, filename: []const u8) ![:0]const u8 {
        const io = ctx.io;
        const allocator = ctx.allocator;
        const file = try std.Io.Dir.cwd().openFile(io, filename, .{});
        defer file.close(io);
        var buffer: [1024]u8 = undefined;
        var file_reader = file.reader(io, &buffer);
        const reader = &file_reader.interface;
        var allocating_writer = std.Io.Writer.Allocating.init(allocator);
        const writer = &allocating_writer.writer;
        try writer.writeAll(shader_header);
        _ = try reader.streamRemaining(writer);
        return allocating_writer.toOwnedSliceSentinel(0);
    }

    fn handleLoadShaderFileError(filename: []const u8, err: anyerror) ?[:0]const u8 {
        std.log.err("Error loading shader file {s}: {t}", .{ filename, err });
        return null;
    }

    const resources_root = comptimePathJoin(&.{ "src", "resources" });

    fn resourceFilename(comptime sub_path: []const u8) [:0]const u8 {
        return comptimePathJoin(&.{ resources_root, sub_path });
    }

    fn textureKeyToFilename(key: TextureKey) [:0]const u8 {
        return switch (key) {
            .spritesheet => resourceFilename("spritesheet.png"),
            .bg => resourceFilename("bg.png"),
        };
    }

    fn soundKeyToFilename(key: SoundKey) [:0]const u8 {
        return switch (key) {
            .example => resourceFilename("example.wav"),
        };
    }

    fn musicKeyToFilename(key: MusicKey) [:0]const u8 {
        return switch (key) {
            .example => resourceFilename("example.mp3"),
        };
    }

    fn shaderKeyToFilename(key: ShaderKey) [:0]const u8 {
        return switch (key) {
            .crt => resourceFilename(";crt.fs"),
            .god_rays => resourceFilename(";god-rays.fs"),
            .sobel => resourceFilename(";sobel.fs"),
        };
    }

    pub const InitOptions = union(enum) {
        load_all,
        load_these: []const std.meta.FieldEnum(Assets),
        empty,
    };

    pub const empty = @This(){};

    pub fn init(ctx: LoadAssetContext, comptime options: InitOptions) @This() {
        var self: @This() = .empty;

        switch (options) {
            .load_all => self.loadAll(ctx),
            .load_these => |these| self.loadThese(ctx, these),
            .empty => {},
        }

        return self;
    }

    pub fn loadAll(self: *@This(), ctx: LoadAssetContext) void {
        self.loadThese(ctx, std.meta.tags(std.meta.FieldEnum(@This())));
    }

    pub fn loadThese(
        self: *@This(),
        ctx: LoadAssetContext,
        comptime fields: []const std.meta.FieldEnum(@This()),
    ) void {
        inline for (fields) |tag| {
            @field(self, @tagName(tag)).loadAll(ctx);
        }
    }
};
