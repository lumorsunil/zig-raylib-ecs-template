const Game = @import("../game.zig").Game;

pub const Camera = struct {
    enabled: bool = true,
    follow_x: bool = false,
    follow_y: bool = false,

    pub fn init() @This() {
        return .{};
    }

    pub fn update(self: *Camera, game: *Game) void {
        const controllable = game.getOneByTag(Game.C.Controllable);
        const body = controllable.tryGetConst(Game.C.Body) orelse return;

        const camera = game.camera();
        const pixel_size = game.pixelSize();
        const position = body.position();

        if (self.follow_x) {
            camera.target.x = position.x - pixel_size.x / 2;
        }
        if (self.follow_y) {
            camera.target.y = position.y - pixel_size.y / 2;
        }
    }
};
