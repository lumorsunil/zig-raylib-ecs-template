const Game = @import("game.zig").Game;

pub fn setupSystems(game: *Game) void {
    game.addSingleton(Game.S.Animation.init());
    game.addSingleton(Game.S.Camera.init());
    game.addSingleton(Game.S.Controllable.init());
    game.addSingleton(Game.S.DestroyEntities.init());
    game.addSingleton(Game.S.Input.init());
    game.addSingleton(Game.S.Physics.init(game));
    game.addSingleton(Game.S.RelativePosition.init());
    game.addSingleton(Game.S.StateMachine.init());
    game.addSingleton(Game.S.Event.init(game));
}
