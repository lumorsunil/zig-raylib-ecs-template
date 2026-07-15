const Game = @import("../game.zig").Game;

pub const Animation = struct {
    animation: AnimationFrames,
    is_looping: bool,
    next_frame_at: f64 = 0,
    current_frame: usize = 0,
    paused_at: f64 = 0,
    is_playing: bool = true,

    pub fn init(animation: AnimationFrames, is_looping: bool) @This() {
        return .{ .animation = animation, .is_looping = is_looping };
    }

    pub fn start(self: *@This(), t: f64) void {
        self.next_frame_at = t + self.animation.frame_duration;
        self.current_frame = 0;
        self.is_playing = true;
    }

    pub fn pause(self: *@This(), t: f64) void {
        self.is_playing = false;
        self.paused_at = t;
    }

    pub fn unpause(self: *@This(), t: f64) void {
        self.is_playing = false;
        self.next_frame_at += t - self.paused_at;
    }

    pub fn getFrame(self: @This()) Game.C.Renderable {
        const i = @min(self.current_frame, self.animation.frames.len - 1);
        return self.animation.frames[i].renderable;
    }

    pub fn isDone(self: @This()) bool {
        return !self.is_looping and self.current_frame >= self.animation.frames.len;
    }

    pub const AnimationUpdateEvent = enum { next_frame, looped, none };

    pub fn update(self: *@This(), t: f64) AnimationUpdateEvent {
        if (!self.is_playing) return .none;

        var event: AnimationUpdateEvent = .none;

        if (self.next_frame_at <= t) {
            event = .next_frame;

            self.current_frame += 1;

            if (self.is_looping) {
                self.current_frame %= self.animation.frames.len;

                if (self.current_frame == 0) {
                    event = .looped;
                }
            }

            if (!self.isDone()) {
                self.next_frame_at = t + self.animation.frame_duration * self.animation.frames[self.current_frame].duration_factor;
            }
        }

        return event;
    }

    pub const AnimationFrames = struct {
        frames: []const Frame,
        frame_duration: f64,

        pub fn init(frames: []const Frame, frame_duration: f64) @This() {
            return .{ .frames = frames, .frame_duration = frame_duration };
        }
    };

    pub const Frame = struct {
        renderable: Game.C.Renderable,
        duration_factor: f32,

        pub fn init(renderable: Game.C.Renderable, duration_factor: f32) @This() {
            return .{ .renderable = renderable, .duration_factor = duration_factor };
        }
    };
};
