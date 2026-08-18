const std = @import("std");
const Game = @import("../../game.zig").Game;
const Axis = Game.S.Physics.Axis;

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

        pub fn cellSize(_: @This()) Game.L.Vector2 {
            return .{ 32, 32 };
        }

        pub const CellCandidates = struct {
            min_x: usize,
            min_y: usize,
            max_x: usize,
            max_y: usize,

            pub fn init(grid: G, hitbox: Game.L.Rectangle) @This() {
                const cell_size = grid.cellSize();

                const hitbox_min = @round(hitbox.min());
                const hitbox_max = @max(hitbox_min, @round(hitbox.max()) - Game.L.V.scalar2(1));

                const min = Game.L.V.toInt(
                    usize,
                    grid.clampToGrid(@divFloor(hitbox_min, cell_size)),
                );
                const max = Game.L.V.toInt(
                    usize,
                    grid.clampToGrid(@divFloor(hitbox_max, cell_size)),
                );

                return .{ .min_x = min[0], .min_y = min[1], .max_x = max[0], .max_y = max[1] };
            }

            pub fn format(
                self: @This(),
                writer: *std.Io.Writer,
            ) std.Io.Writer.Error!void {
                try writer.print("Candidates{{min=({},{}) max=({},{})}}", .{ self.min_x, self.min_y, self.max_x, self.max_y });
            }
        };

        fn clampToGrid(self: @This(), v: Game.L.Vector2) Game.L.Vector2 {
            const size = Game.L.V.v2(self.width, self.height);
            return @max(Game.L.V.scalar2(0), @min(size - Game.L.V.scalar2(1), v));
        }

        fn getRecPos(rec: Game.L.Rectangle, comptime axis: Axis) f32 {
            return switch (comptime axis) {
                .x => rec.position[0],
                .y => rec.position[1],
            };
        }

        fn getRecSize(rec: Game.L.Rectangle, comptime axis: Axis) f32 {
            return switch (comptime axis) {
                .x => rec.size[0],
                .y => rec.size[1],
            };
        }

        fn getVectorComponent(v: Game.L.Vector2, comptime axis: Axis) f32 {
            return switch (comptime axis) {
                .x => v[0],
                .y => v[1],
            };
        }

        pub const ResolveCollisionEvent = union(enum) {
            none,
            collision: struct {
                depth: f32,
                direction: f32,
                axis: Axis,
            },
        };

        pub fn resolveCollisions(
            self: *@This(),
            game: *Game,
            ctx: Game.L.EntityContext,
            body: *Game.C.Body,
            callback: *const fn (Game.L.EntityContext, *Game.C.Body, ResolveCollisionEvent) void,
            comptime axiis: []const Axis,
        ) void {
            const hitbox = game.hitbox(ctx);
            const candidates = CellCandidates.init(self.*, hitbox);
            const cell_size = self.cellSize();

            for (candidates.min_x..candidates.max_x + 1) |x| {
                for (candidates.min_y..candidates.max_y + 1) |y| {
                    if (!self.isSolid(game, x, y)) continue;

                    const cell_pos = Game.L.V.v2(x, y) * cell_size;

                    inline for (comptime axiis) |axis| {
                        const body_min = getRecPos(hitbox, axis);
                        const body_max = body_min + getRecSize(hitbox, axis);
                        const cell_min = getVectorComponent(cell_pos, axis);
                        const cell_max = cell_min + getVectorComponent(cell_size, axis);

                        const d_min = body_min - cell_max;
                        const d_max = cell_min - body_max;

                        const correction = if (@abs(d_min) < @abs(d_max)) -d_min else d_max;

                        body.applyToComponent(.position(.from(axis)), .add(correction));
                        body.applyToComponent(.position(.from(axis)), .round);
                        body.applyToComponent(.velocity(.from(axis)), .set(0));

                        callback(ctx, body, .{ .collision = .{
                            .depth = @abs(correction),
                            .direction = -std.math.sign(correction),
                            .axis = axis,
                        } });
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
