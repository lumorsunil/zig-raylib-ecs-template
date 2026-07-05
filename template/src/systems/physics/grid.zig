const std = @import("std");
const Game = @import("../../game.zig").Game;
const Axis = @import("../physics.zig").Axis;
const rl = @import("raylib");

pub fn GridOptions(comptime Cell: type) type {
    return struct {
        comptime Cell: type = Cell,
        isSolid: *const fn (game: *Game, cell: Cell) bool,
    };
}

pub fn Grid(comptime Cell: type, comptime options: GridOptions(Cell)) type {
    return struct {
        data: []Cell,
        width: usize,
        height: usize,

        const G = @This();

        pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !@This() {
            return .{
                .data = try allocator.alloc(Cell, width * height),
                .width = width,
                .height = height,
            };
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            for (self.data) |cell| {
                if (@hasDecl(Cell, "deinit")) {
                    cell.deinit(allocator);
                }
            }
            allocator.free(self.data);
        }

        pub fn cellSize(_: @This()) Game.Vector {
            return .init(32, 32);
        }

        pub const CellCandidates = struct {
            min_x: usize,
            min_y: usize,
            max_x: usize,
            max_y: usize,

            pub fn init(grid: G, hitbox: rl.Rectangle) @This() {
                const cell_size = grid.cellSize();

                const hitbox_min_x = @round(hitbox.x);
                const hitbox_max_x = @round(hitbox.x + hitbox.width);
                const hitbox_min_y = @round(hitbox.y);
                const hitbox_max_y = @round(hitbox.y + hitbox.height);

                const min_x: usize = @intFromFloat(grid.clampXToGrid(@divFloor(hitbox_min_x, cell_size.x)));
                const min_y: usize = @intFromFloat(grid.clampYToGrid(@divFloor(hitbox_min_y, cell_size.y)));
                const max_x: usize = @intFromFloat(grid.clampXToGrid(@ceil(hitbox_max_x / cell_size.x)));
                const max_y: usize = @intFromFloat(grid.clampYToGrid(@ceil(hitbox_max_y / cell_size.y)));

                return .{
                    .min_x = min_x,
                    .min_y = min_y,
                    .max_x = max_x,
                    .max_y = max_y,
                };
            }

            pub fn isEmpty(self: @This()) bool {
                const width = self.max_x - self.min_x;
                const height = self.max_y - self.min_y;

                return width == 0 or height == 0;
            }

            pub fn format(
                self: @This(),
                writer: *std.Io.Writer,
            ) std.Io.Writer.Error!void {
                try writer.print("Candidates{{min=({},{}) max=({},{})}}", .{ self.min_x, self.min_y, self.max_x, self.max_y });
            }
        };

        fn clampXToGrid(self: @This(), x: f32) f32 {
            const fwidth: f32 = @floatFromInt(self.width);
            return @max(0, @min(fwidth, x));
        }

        fn clampYToGrid(self: @This(), y: f32) f32 {
            const fheight: f32 = @floatFromInt(self.height);
            return @max(0, @min(fheight, y));
        }

        fn getRecPos(rec: rl.Rectangle, comptime axis: Axis) f32 {
            return switch (comptime axis) {
                .x => rec.x,
                .y => rec.y,
            };
        }

        fn getRecSize(rec: rl.Rectangle, comptime axis: Axis) f32 {
            return switch (comptime axis) {
                .x => rec.width,
                .y => rec.height,
            };
        }

        fn getVectorComponent(v: Game.Vector, comptime axis: Axis) f32 {
            return switch (comptime axis) {
                .x => v.x,
                .y => v.y,
            };
        }

        fn addToVectorComponent(v: *Game.Vector, value: f32, comptime axis: Axis) void {
            switch (comptime axis) {
                .x => v.x += value,
                .y => v.y += value,
            }
        }

        fn roundVectorComponent(v: *Game.Vector, comptime axis: Axis) void {
            switch (comptime axis) {
                .x => v.x = @round(v.x),
                .y => v.y = @round(v.y),
            }
        }

        pub fn resolveCollisions(
            self: *@This(),
            game: *Game,
            ctx: Game.EntityContext,
            body: *Game.C.Body,
            comptime axiis: []const Axis,
        ) void {
            const hitbox = game.hitbox(ctx);
            const candidates = CellCandidates.init(self.*, hitbox.hitbox);
            const cell_size = self.cellSize();

            if (candidates.isEmpty()) return;

            for (candidates.min_x..candidates.max_x) |x| {
                for (candidates.min_y..candidates.max_y) |y| {
                    if (!self.isSolid(game, x, y)) continue;

                    const cell_pos = Game.Vector.init(@floatFromInt(x), @floatFromInt(y)).multiply(cell_size);

                    inline for (comptime axiis) |axis| {
                        const body_min = getRecPos(hitbox.hitbox, axis);
                        const body_max = body_min + getRecSize(hitbox.hitbox, axis);
                        const cell_min = getVectorComponent(cell_pos, axis);
                        const cell_max = cell_min + getVectorComponent(cell_size, axis);

                        const d_min = body_min - cell_max;
                        const d_max = cell_min - body_max;

                        const correction = if (@abs(d_min) < @abs(d_max)) -d_min else d_max;

                        std.log.debug("hitbox: {f}", .{hitbox});
                        std.log.debug("candidates: {f}", .{candidates});
                        std.log.debug("correction ({t}): {}", .{ axis, correction });

                        addToVectorComponent(&body.position, correction, axis);
                        roundVectorComponent(&body.position, axis);
                    }

                    return;
                }
            }
        }

        pub fn getCell(self: @This(), x: usize, y: usize) Cell {
            return self.data[x + y * self.width];
        }

        pub fn isSolid(self: @This(), game: *Game, x: usize, y: usize) bool {
            return options.isSolid(game, self.getCell(x, y));
        }
    };
}

pub const DefaultCell = struct {
    is_solid: bool = false,

    pub fn isSolid(_: *Game, cell: @This()) bool {
        return cell.is_solid;
    }
};

pub const default_grid_options = GridOptions(DefaultCell){
    .isSolid = DefaultCell.isSolid,
};

pub const DefaultGrid = Grid(DefaultCell, default_grid_options);
