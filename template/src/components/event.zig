const std = @import("std");
const Allocator = std.mem.Allocator;
const Game = @import("../game.zig").Game;

pub const Event = struct {
    events: std.ArrayList(EntityEvent) = .empty,

    pub fn init(events: []const EntityEvent, allocator: Allocator) @This() {
        return .{ .events = .fromOwnedSlice(allocator.dupe(EntityEvent, events) catch unreachable) };
    }

    pub fn deinit(self: *@This(), allocator: Allocator) void {
        self.events.deinit(allocator);
    }

    pub fn emit(self: *@This(), allocator: Allocator, event: EntityEvent) void {
        self.events.append(allocator, event) catch unreachable;
    }

    pub const EntityEventTag = enum {
        move_done,
        action_done,
    };

    pub const EntityEvent = union(EntityEventTag) {
        move_done: MoveDone,
        action_done: ActionDone,

        pub const MoveDone = void;
        pub const ActionDone = void;
    };
};
