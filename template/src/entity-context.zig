const std = @import("std");
const Game = @import("game.zig").Game;
const ecs = @import("ecs");

pub const EntityContext = struct {
    game: *Game,
    entity: ecs.Entity,

    pub fn init(game: *Game, entity: ecs.Entity) @This() {
        return .{ .game = game, .entity = entity };
    }

    pub fn equals(self: EntityContext, other: EntityContext) bool {
        return self.entity.index == other.entity.index;
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

    pub const addCE = @import("component-enum.zig").addCE;

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

    pub fn addBody(self: @This()) *Game.C.Body {
        const body = Game.C.Body.init(self);
        self.add(body);
        return self.get(Game.C.Body);
    }

    pub fn emitEvent(self: @This(), event: Game.C.Event.EntityEvent) void {
        std.log.debug("event: {t}", .{event});

        const event_container = self.tryGet(Game.C.Event) orelse {
            self.add(Game.C.Event.init(&.{event}, self.game.allocator));
            return;
        };

        event_container.emit(self.game.allocator, event);
    }
};
