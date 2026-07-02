const std = @import("std");
const ecs = @import("ecs");
const rl = @import("raylib");

pub const Game = struct {
    io: std.Io,
    allocator: std.mem.Allocator,
    reg: ecs.Registry,
    random_io: std.Random.IoSource,

    pub const Camera = rl.Camera2D;
    pub const Vector = rl.Vector2;
    pub const Color = rl.Color;

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
        self.reg.deinit();
        rl.closeWindow();
    }

    pub fn run(self: *@This()) void {
        while (!rl.windowShouldClose()) {
            self.update();
            rl.beginDrawing();
            self.draw();
            rl.endDrawing();
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

    pub fn elapsedTime(_: @This()) f64 {
        return rl.getTime();
    }

    pub fn deltaTime(_: @This()) f32 {
        return rl.getFrameTime();
    }

    pub fn screenSize(self: @This()) Vector {
        return self.pixelSize().scale(self.zoom());
    }

    pub fn pixelSize(_: @This()) Vector {
        return .init(320, 256);
    }

    pub fn addSingleton(self: *@This(), singleton: anytype) void {
        self.reg.singletons().add(singleton);
    }

    pub fn getSingleton(self: *@This(), comptime T: type) *T {
        return self.reg.singletons().get(T);
    }

    pub fn camera(self: *@This()) *Camera {
        return self.getSingleton(Camera);
    }

    pub fn input(self: *@This()) *Game.S.Input {
        return self.getSingleton(Game.S.Input);
    }

    pub fn createEntity(self: *@This()) EntityContext {
        return .init(self, self.reg.create());
    }

    pub fn destroyEntity(self: *@This(), entity: ecs.Entity) void {
        const destroy_entities = self.getSingleton(Game.S.DestroyEntities);
        destroy_entities.destroy(entity);
    }

    pub const EntityContext = struct {
        game: *Game,
        entity: ecs.Entity,

        pub fn init(game: *Game, entity: ecs.Entity) @This() {
            return .{ .game = game, .entity = entity };
        }

        pub fn get(self: EntityContext, comptime T: type) *T {
            return self.game.reg.get(T, self.entity);
        }

        pub fn getConst(self: EntityContext, comptime T: type) T {
            return self.game.reg.getConst(T, self.entity);
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
};
