const std = @import("std");
const Allocator = std.mem.Allocator;
const Game = @import("../game.zig").Game;

pub const Event = struct {
    game: *Game,
    listeners: std.AutoHashMap(Game.C.Event.EntityEventTag, std.ArrayList(EntityEventListener)),

    pub fn init(game: *Game) @This() {
        return .{
            .game = game,
            .listeners = .init(game.allocator),
        };
    }

    pub fn deinit(self: *@This()) void {
        var it = self.listeners.valueIterator();

        while (it.next()) |listeners| {
            listeners.deinit(self.game.allocator);
        }

        self.listeners.deinit();
    }

    pub fn update(self: *@This()) void {
        const game = self.game;
        var it = game.entityIterator(.{Game.C.Event}, .{});

        var events_to_remove = std.ArrayList(Game.L.EntityContext).empty;
        defer events_to_remove.deinit(self.game.allocator);

        while (it.next()) |ctx| {
            const event_container = ctx.get(Game.C.Event);

            for (event_container.events.items) |event| {
                const listeners = self.listeners.get(event) orelse continue;

                for (listeners.items) |listener| {
                    listener(ctx, event);
                }
            }

            events_to_remove.append(self.game.allocator, ctx) catch unreachable;
        }

        for (events_to_remove.items) |ctx| {
            const event_container = ctx.get(Game.C.Event);
            event_container.deinit(self.game.allocator);
            ctx.remove(Game.C.Event);
        }
    }

    pub fn on(
        self: *@This(),
        event_type: Game.C.Event.EntityEventTag,
        listener: EntityEventListener,
    ) void {
        if (!self.listeners.contains(event_type)) {
            self.listeners.put(event_type, .empty) catch unreachable;
        }

        const listeners = self.listeners.getPtr(event_type).?;
        listeners.append(self.game.allocator, listener) catch unreachable;
    }

    pub fn off(
        self: *@This(),
        event_type: Game.C.Event.EntityEventTag,
        listener: EntityEventListener,
    ) void {
        const listeners = self.listeners.getPtr(event_type) orelse return;
        const i = std.mem.indexOfScalar(EntityEventListener, listeners.items, listener) orelse return;
        _ = listeners.orderedRemove(i);
    }

    pub const EntityEventListener = *const fn (Game.L.EntityContext, event: Game.C.Event.EntityEvent) void;
};
