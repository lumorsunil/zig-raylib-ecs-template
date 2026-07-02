const Game = @import("../game.zig").Game;

pub const Camera = struct {
    enabled: bool = true,
    follow_x: bool = false,
    follow_y: bool = false,

    pub fn init() @This() {
        return .{};
    }

    pub fn update(self: *Camera, game: *Game) void {
        var it = game.entityIterator(.{ Game.C.Controllable, Game.C.Body }, .{});
        const camera = game.camera();
        const pixel_size = game.pixelSize();

        while (it.next()) |ctx| {
            const body = ctx.getConst(Game.C.Body);

            if (self.follow_x) {
                camera.target.x = body.position.x - pixel_size.x / 2;
            }
            if (self.follow_y) {
                camera.target.y = body.position.y - pixel_size.y / 2;
            }
        }
    }
};
