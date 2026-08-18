const Game = @import("game.zig").Game;

pub fn update(self: *Game) void {
    switch (self.screen_state) {
        .menu => updateMenu(self),
        .gameplay => updateGameplay(self),
        .game_over => updateGameOver(self),
        .ending => updateEnding(self),
    }
}

pub fn updateMenu(self: *Game) void {
    _ = self;
}

pub fn updateGameplay(self: *Game) void {
    self.updateTime();

    const state_machine = self.getSingleton(Game.S.StateMachine);
    state_machine.update(self);

    self.input().update();
    self.controllable().update(self);

    self.physics().update(self);
    const relative_position = self.getSingleton(Game.S.RelativePosition);
    relative_position.update(self);

    self.cameraSystem().update(self);

    const animation = self.getSingleton(Game.S.Animation);
    animation.update(self);

    const event = self.getSingleton(Game.S.Event);
    event.update();

    self.destroyEntitiesSystem().update(self);
}

pub fn updateGameOver(self: *Game) void {
    _ = self;
}

pub fn updateEnding(self: *Game) void {
    _ = self;
}
