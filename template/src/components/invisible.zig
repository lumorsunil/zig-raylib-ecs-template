pub const Invisible = struct {
    enabled: bool = true,

    pub fn init() @This() {
        return .{};
    }
};
