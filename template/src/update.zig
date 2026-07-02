const Game = @import("game.zig").Game;

pub fn update(self: *Game) void {
    self.input().update();
    const controllable = self.getSingleton(Game.S.Controllable);
    controllable.update(self);
    const physics = self.getSingleton(Game.S.Physics);
    physics.update(self);
    const camera = self.getSingleton(Game.S.Camera);
    camera.update(self);
    const destroy_entities = self.getSingleton(Game.S.DestroyEntities);
    destroy_entities.update(self);
}
