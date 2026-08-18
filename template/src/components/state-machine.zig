const std = @import("std");
const Game = @import("../game.zig").Game;

const sm_mod = @import("../systems/state-machine.zig");
const StateFunction = Game.L.StateFunction;
const StateMachineKey = sm_mod.StateMachineKey;
const StateMachineKeyFilter = sm_mod.StateMachineKeyFilter;
const default_key = sm_mod.default_key;

pub const StateMachine = struct {
    states: std.array_hash_map.String(StateMachineInternal) = .empty,

    pub fn init() StateMachine {
        return .{};
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.states.deinit(allocator);
    }

    pub fn registerStateMachine(
        self: *@This(),
        allocator: std.mem.Allocator,
        initial_state: *const StateFunction,
    ) void {
        return self.registerStateMachineByKey(allocator, default_key, initial_state);
    }

    pub fn registerStateMachineByKey(
        self: *@This(),
        allocator: std.mem.Allocator,
        key: StateMachineKey,
        initial_state: *const StateFunction,
    ) void {
        self.states.put(allocator, key, .init(initial_state)) catch unreachable;
    }

    pub fn enable(self: *StateMachine, filter: StateMachineKeyFilter) void {
        var it = filter.iterator(self);

        while (it.next()) |s| {
            s.enable();
        }
    }

    pub fn disable(self: *StateMachine, filter: StateMachineKeyFilter) void {
        var it = filter.iterator(self);

        while (it.next()) |s| {
            s.disable();
        }
    }

    pub const Internal = StateMachineInternal;
};

const StateMachineInternal = struct {
    enabled: bool = true,
    state: *const StateFunction,
    post: ?*const StateFunction = null,

    pub fn init(state: *const StateFunction) @This() {
        return .{ .state = state };
    }

    pub fn enable(self: *@This()) void {
        self.enabled = true;
    }

    pub fn disable(self: *@This()) void {
        self.enabled = false;
    }
};
