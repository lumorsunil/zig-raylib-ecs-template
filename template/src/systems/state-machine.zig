const std = @import("std");
const ecs = @import("ecs");
const Game = @import("../game.zig").Game;

const StateMachine = Game.C.StateMachine;

pub const default_key: StateMachineKey = "default";
const stateMachineErrorHeader = "StateMachine error: ";

pub fn validateFnInStruct(
    comptime T: type,
    comptime fnName: []const u8,
    comptime expectedParams: []const type,
    comptime expectedReturnType: type,
) void {
    const errorHeader = stateMachineErrorHeader ++ @typeName(T) ++ "." ++ fnName;

    if (!@hasDecl(T, fnName)) {
        @compileError(errorHeader ++ ": not implemented");
    }

    const Fn = @TypeOf(@field(T, fnName));

    validateFn(Fn, expectedParams, expectedReturnType, errorHeader);
}

pub fn validateFn(
    comptime Fn: type,
    comptime expectedParams: []const type,
    comptime expectedReturnType: type,
    comptime errorHeader: []const u8,
) void {
    switch (@typeInfo(Fn)) {
        .@"fn" => |typeInfo| {
            const rt = typeInfo.return_type orelse void;
            if (rt != expectedReturnType) {
                @compileError(errorHeader ++ ": invalid return type " ++ @typeName(rt) ++ ", expected " ++ @typeName(expectedReturnType));
            }
            if (typeInfo.params.len != expectedParams.len) {
                @compileError(std.fmt.comptimePrint(errorHeader ++ ": invalid number of parameters: {}, expected: {}", .{ typeInfo.params.len, expectedParams.len }));
            }
        },
        else => {
            @compileError(errorHeader ++ ": has to be a function");
        },
    }
}

pub const StateMachineContext = struct {
    entity: Game.L.EntityContext,

    pub fn init(entity: Game.L.EntityContext) StateMachineContext {
        return .{ .entity = entity };
    }

    pub fn enable(ctx: StateMachineContext) void {
        ctx.entity.get(StateMachine).enable(.key(default_key));
    }

    pub fn enableByFilter(ctx: StateMachineContext, filter: StateMachineKeyFilter) void {
        ctx.entity.get(StateMachine).enable(filter);
    }

    pub fn disable(ctx: StateMachineContext) void {
        ctx.entity.get(StateMachine).disable(.key(default_key));
    }

    pub fn disableByFilter(ctx: StateMachineContext, filter: StateMachineKeyFilter) void {
        ctx.entity.get(StateMachine).disable(filter);
    }

    pub fn isEnabled(ctx: StateMachineContext) bool {
        return ctx.isEnabledByKey(default_key);
    }

    pub fn isEnabledByKey(ctx: StateMachineContext, key: StateMachineKey) bool {
        const sm = ctx.stateMachineByKey(key) orelse return false;
        return sm.enabled;
    }

    pub fn stateMachine(self: StateMachineContext) ?*StateMachine.Internal {
        return self.stateMachineByKey(default_key);
    }

    pub fn stateMachineByKey(
        self: StateMachineContext,
        key: StateMachineKey,
    ) ?*StateMachine.Internal {
        const sm = self.tryGet(StateMachine) orelse return null;
        return sm.states.getPtr(key);
    }

    pub fn setState(ctx: StateMachineContext, comptime newState: anytype) void {
        ctx.setStateForKey(default_key, newState);
    }

    pub fn setStateForKey(
        ctx: StateMachineContext,
        key: StateMachineKey,
        comptime newState: anytype,
    ) void {
        validateState(newState);

        const sm = ctx.tryGet(StateMachine) orelse return;
        const smi = sm.states.getPtr(key) orelse @panic(std.fmt.allocPrint(
            ctx.allocator(),
            "state machine internal not found for key: {s}",
            .{key},
        ) catch unreachable);

        if (smi.post) |post| {
            post(ctx);
            smi.post = null;
        }

        // TODO: Should we remove the state duration automatically here?

        switch (@typeInfo(@TypeOf(newState))) {
            .type => {
                if (@hasDecl(newState, "pre")) newState.pre(ctx);
                smi.state = newState.update;
                if (@hasDecl(newState, "post")) smi.post = newState.post;
            },
            .@"fn" => {
                smi.state = newState;
            },
            else => {
                @compileError("Invalid state type: " ++ @typeName(@TypeOf(newState)));
            },
        }
    }

    pub fn createTimer(ctx: StateMachineContext, duration: f64) f64 {
        return ctx.game + duration;
    }

    pub fn isTimerExpired(ctx: StateMachineContext, timer: f64) bool {
        return timer <= ctx.t;
    }

    pub fn isState(ctx: StateMachineContext, state: anytype) bool {
        const current_state = ctx.stateMachine().?.state;

        return switch (@typeInfo(@TypeOf(state))) {
            .type => state.update == current_state,
            .@"fn" => state == current_state,
            else => @compileError("Invalid state comparison"),
        };
    }

    pub fn isStateByKey(
        ctx: StateMachineContext,
        key: StateMachineKey,
        state: anytype,
    ) bool {
        const current_state = ctx.stateMachineByKey(key).?.state;

        return switch (@typeInfo(@TypeOf(state))) {
            .type => state.update == current_state,
            .@"fn" => state == current_state,
            else => @compileError("Invalid state comparison"),
        };
    }
};

pub const StateFunction = fn (StateMachineContext) void;

pub const StateMachineKey = []const u8;

pub const StateMachineKeyFilter = union(enum) {
    key_: StateMachineKey,
    all,

    pub fn key(key_: StateMachineKey) @This() {
        return .{ .key_ = key_ };
    }

    pub fn iterator(self: @This(), state_machine: *StateMachine) FilterIterator {
        return switch (self) {
            .key_ => |key_| .{ .key = .init(state_machine, key_) },
            .all => .{ .all = .init(state_machine) },
        };
    }
};

const FilterIterator = union(enum) {
    key: FilterKeyIterator,
    all: FilterAllIterator,

    pub fn next(self: *@This()) ?*StateMachine.Internal {
        return switch (self.*) {
            inline else => |*s| s.next(),
        };
    }
};

const FilterKeyIterator = struct {
    state_machine: *StateMachine,
    key: StateMachineKey,
    consumed: bool = false,

    pub fn init(state_machine: *StateMachine, key: StateMachineKey) @This() {
        return .{ .state_machine = state_machine, .key = key };
    }

    pub fn next(self: *@This()) ?*StateMachine.Internal {
        if (self.consumed) return null;
        defer self.consumed = true;
        return self.state_machine.states.getPtr(self.key);
    }
};

const FilterAllIterator = struct {
    state_machine: *StateMachine,
    index: ?usize = 0,

    pub fn init(state_machine: *StateMachine) @This() {
        return .{ .state_machine = state_machine };
    }

    pub fn next(self: *@This()) ?*StateMachine.Internal {
        const index = if (self.index) |*idx| idx else return null;
        if (index.* >= self.state_machine.states.count()) {
            self.index = null;
            return null;
        }
        // defer index.* += 1;
        // return &self.state_machine.states.values()[index.*];
        const item = &self.state_machine.states.values()[index.*];
        index.* += 1;
        return item;
    }
};

pub const StateMachineSystem = struct {
    enabled: bool = true,

    pub fn init() @This() {
        return .{};
    }

    pub fn update(_: *@This(), game: *Game) void {
        var it = game.entityIterator(.{StateMachine}, .{});

        while (it.next()) |ctx| {
            const state_machine = ctx.get(StateMachine);

            var sm_it = StateMachineKeyFilter.iterator(.all, state_machine);

            while (sm_it.next()) |sm| {
                sm.state(.init(ctx));
            }
        }
    }
};

pub fn validateState(comptime state: anytype) void {
    const errorHeader = std.fmt.comptimePrint("{s}", .{@typeName(@TypeOf(state))});

    switch (@typeInfo(@TypeOf(state))) {
        .type => {
            inline for (std.meta.fields(state)) |field| {
                if (std.mem.eql(u8, field.name, "pre")) continue;
                if (std.mem.eql(u8, field.name, "update")) continue;
                if (std.mem.eql(u8, field.name, "post")) continue;

                @compileError(errorHeader ++ ": Unknown function " ++ field.name ++ "");
            }

            if (@hasDecl(state, "pre")) {
                validateFnInStruct(state, "pre", &.{StateMachineContext}, void);
            }
            if (@hasDecl(state, "post")) {
                validateFnInStruct(state, "post", &.{StateMachineContext}, void);
            }
            validateFnInStruct(state, "update", &.{StateMachineContext}, void);
        },
        .@"fn" => {
            validateFn(@TypeOf(state), &.{StateMachineContext}, void, errorHeader);
        },
        else => {
            @compileError("Invalid state type: " ++ @typeName(@TypeOf(state)));
        },
    }
}

fn getStateLabel(comptime state: anytype) []const u8 {
    return switch (@typeInfo(@TypeOf(state))) {
        .type => @typeName(state),
        .@"fn" => "<function>",
        else => @compileError("invalid state"),
    };
}
