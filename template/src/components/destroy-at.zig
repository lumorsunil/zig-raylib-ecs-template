pub const DestroyAt = struct {
    destroy_at: f64,

    pub fn init(destroy_at: f64) @This() {
        return .{ .destroy_at = destroy_at };
    }
};
