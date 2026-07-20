const std = @import("std");
const Allocator = std.mem.Allocator;
const comptimePrint = std.fmt.comptimePrint;
const fmtJoin = std.fs.path.fmtJoin;
const rl = @import("raylib");

fn comptimePathJoin(comptime paths: []const []const u8) [:0]const u8 {
    return comptime comptimePrint("{f}", .{fmtJoin(paths)});
}

pub fn AssetContainerOptions(comptime K: type, comptime V: type) type {
    return struct {
        keyToFilename: *const fn (K) [:0]const u8,
        load: *const fn ([:0]const u8) anyerror!V,
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

        pub fn loadAll(self: *@This(), allocator: Allocator) void {
            inline for (std.meta.tags(K)) |tag| {
                _ = self.load(allocator, tag);
            }
        }

        pub fn keyToFilename(_: @This(), key: K) [:0]const u8 {
            return options.keyToFilename(key);
        }

        pub fn load(
            self: *@This(),
            allocator: Allocator,
            key: K,
        ) ?*V {
            return self.load_aux(allocator, key) catch |err| {
                const filename = self.keyToFilename(key);
                std.log.err("Could not load {s}: {}", .{ filename, err });
                return null;
            };
        }

        fn load_aux(self: *@This(), allocator: Allocator, key: K) !?*V {
            if (self.map.getPtr(key)) |value| return value;
            const filename = self.keyToFilename(key);
            const value: V = try options.load(filename);
            try self.map.put(allocator, key, value);
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
    sounds: Sounds = .empty,
    musics: Musics = .empty,
    shaders: Shaders = .empty,

    pub const TextureKey = enum {
        spritesheet,
    };

    pub const SoundKey = enum {
        example,
    };

    pub const MusicKey = enum {
        example,
    };

    pub const ShaderKey = enum {
        crt,
    };

    pub const Textures = AssetContainer(TextureKey, rl.Texture2D, .{
        .keyToFilename = textureKeyToFilename,
        .load = rl.loadTexture,
        .unload = rl.unloadTexture,
    });

    pub const Sounds = AssetContainer(SoundKey, rl.Sound, .{
        .keyToFilename = soundKeyToFilename,
        .load = rl.loadSound,
        .unload = rl.unloadSound,
    });

    pub const Musics = AssetContainer(MusicKey, rl.Music, .{
        .keyToFilename = musicKeyToFilename,
        .load = rl.loadMusicStream,
        .unload = rl.unloadMusicStream,
    });

    pub const Shaders = AssetContainer(ShaderKey, rl.Shader, .{
        .keyToFilename = shaderKeyToFilename,
        .load = loadShader,
        .unload = rl.unloadShader,
    });
    pub const LoadShaderError = error{InvalidFilename};
    fn loadShader(filenames: [:0]const u8) !rl.Shader {
        const basename = std.fs.path.basename(filenames);
        const dirname = std.fs.path.dirname(filenames) orelse ".";
        var it = std.mem.splitScalar(u8, basename, ';');
        var vs: ?[]const u8 = it.next() orelse return LoadShaderError.InvalidFilename;
        if (vs.?.len == 0) vs = null;
        var fs: ?[]const u8 = it.next() orelse return LoadShaderError.InvalidFilename;
        if (fs.?.len == 0) fs = null;
        var vs_buffer: [1024]u8 = undefined;
        const vsz = if (vs) |s| try std.fmt.bufPrintZ(&vs_buffer, "{f}", .{fmtJoin(&.{ dirname, s })}) else null;
        var fs_buffer: [1024]u8 = undefined;
        const fsz = if (fs) |s| try std.fmt.bufPrintZ(&fs_buffer, "{f}", .{fmtJoin(&.{ dirname, s })}) else null;
        return rl.loadShader(vsz, fsz);
    }

    const resources_root = comptimePathJoin(&.{ "src", "resources" });

    fn resourceFilename(comptime sub_path: []const u8) [:0]const u8 {
        return comptimePathJoin(&.{ resources_root, sub_path });
    }

    fn textureKeyToFilename(key: TextureKey) [:0]const u8 {
        return switch (key) {
            .spritesheet => resourceFilename("spritesheet.png"),
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
        };
    }

    pub const InitOptions = union(enum) {
        load_all,
        load_these: []const std.meta.FieldEnum(Assets),
        empty,
    };

    pub const empty = @This(){};

    pub fn init(allocator: Allocator, comptime options: InitOptions) @This() {
        var self: @This() = .empty;

        switch (options) {
            .load_all => self.loadAll(allocator),
            .load_these => |these| self.loadThese(allocator, these),
            .empty => {},
        }

        return self;
    }

    pub fn loadAll(self: *@This(), allocator: Allocator) void {
        self.loadThese(allocator, std.meta.tags(std.meta.FieldEnum(@This())));
    }

    pub fn loadThese(
        self: *@This(),
        allocator: Allocator,
        comptime fields: []const std.meta.FieldEnum(@This()),
    ) void {
        inline for (fields) |tag| {
            @field(self, @tagName(tag)).loadAll(allocator);
        }
    }
};
