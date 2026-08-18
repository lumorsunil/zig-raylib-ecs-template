const std = @import("std");
const Game = @import("game.zig").Game;

pub const ztracy = @import("ztracy");

pub const ZoneCtx = struct {
    ctx: ztracy.ZoneCtx,

    pub fn init(ctx: ztracy.ZoneCtx) @This() {
        return .{ .ctx = ctx };
    }

    pub fn end(self: @This()) void {
        self.ctx.End();
    }
};

pub fn tracyZoneN(comptime src: std.builtin.SourceLocation, label: [*:0]const u8) ZoneCtx {
    return .init(ztracy.ZoneN(src, label));
}

pub fn tracyZoneNC(
    comptime src: std.builtin.SourceLocation,
    label: [*:0]const u8,
    color: Game.Color,
) ZoneCtx {
    return .init(ztracy.ZoneNC(src, label, @bitCast(color.toInt())));
}
