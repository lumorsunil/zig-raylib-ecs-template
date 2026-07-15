const std = @import("std");
const Allocator = std.mem.Allocator;
const comptimePrint = std.fmt.comptimePrint;
const fmtJoin = std.fs.path.fmtJoin;
const rl = @import("raylib");
const Game = @import("game.zig").Game;

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
    pub const TextureKey = enum {
        spritesheet,
    };

    pub const SoundKey = enum {
        example,
    };

    pub const MusicKey = enum {
        example,
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

    const resources_root = comptimePrint("{f}", .{fmtJoin(&.{ "src", "resources" })});

    fn resourceFilename(comptime sub_path: []const u8) [:0]const u8 {
        return comptimePrint("{f}", .{comptime fmtJoin(&.{ resources_root, sub_path })});
    }

    fn textureKeyToFilename(texture: Game.Assets.TextureKey) [:0]const u8 {
        return switch (texture) {
            .spritesheet => resourceFilename("spritesheet.png"),
        };
    }

    fn soundKeyToFilename(sound: Game.Assets.SoundKey) [:0]const u8 {
        return switch (sound) {
            .example => resourceFilename("example.wav"),
        };
    }

    fn musicKeyToFilename(sound: Game.Assets.MusicKey) [:0]const u8 {
        return switch (sound) {
            .example => resourceFilename("example.mp3"),
        };
    }

    pub fn loadAllTextures(allocator: Allocator) Textures {
        var textures: Textures = .empty;

        inline for (std.enums.values(TextureKey)) |texture| {
            _ = textures.load(allocator, texture);
        }

        return textures;
    }

    pub fn loadAllSounds(allocator: Allocator) Sounds {
        var sounds: Sounds = .empty;

        inline for (std.enums.values(SoundKey)) |sound| {
            _ = sounds.load(allocator, sound);
        }

        return sounds;
    }

    pub fn loadAllMusic(allocator: Allocator) Musics {
        var musics: Musics = .empty;

        inline for (std.enums.values(MusicKey)) |music| {
            _ = musics.load(allocator, music);
        }

        return musics;
    }
};
