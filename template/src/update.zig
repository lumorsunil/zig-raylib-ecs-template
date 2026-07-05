const Game = @import("game.zig").Game;

pub fn update(self: *Game) void {
    self.input().update();
    self.controllable().update(self);
    self.physics().update(self);
    const relative_position = self.getSingleton(Game.S.RelativePosition);
    relative_position.update(self);
    self.cameraSystem().update(self);
    self.destroyEntitiesSystem().update(self);
}
