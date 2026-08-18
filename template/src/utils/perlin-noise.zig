const std = @import("std");

pub const PerlinNoise2D = struct {
    random: std.Random.Xoshiro256,
    permutation: [256]usize,

    pub fn init(seed: u64) @This() {
        // // 256 permutation array duplicated to avoid buffer overflow lookups
        // p = list(range(256))
        // // Hardcoded shuffle representing a standardized pseudo-random distribution
        // random.shuffle(p)
        // self.permutation = p * 2

        var p: [256]usize = undefined;
        var permutation: [p.len]usize = undefined;
        for (0..p.len) |i| p[i] = i;

        var random = std.Random.Xoshiro256.init(seed);
        random.random().shuffle(usize, &p);

        for (0..p.len) |i| permutation[i] = p[i] * 2;

        return .{
            .random = random,
            .permutation = permutation,
        };
    }

    pub fn _fade(t: f32) f32 {
        // 6t^5 - 1Xoshiro2565t^4 + 10t^3
        return t * t * t * (t * (t * 6 - 15) + 10);
    }

    pub fn _lerp(t: f32, a: f32, b: f32) f32 {
        return a + t * (b - a);
    }

    pub fn _grad(hash_val: usize, x: f32, y: f32) f32 {
        // Convert the hash into 1 of 4 diagonal gradient vectors:
        // (1,1), (-1,1), (1,-1), or (-1,-1)
        const h = hash_val & 3;
        const u = if (h < 2) x else -x;
        const v = if (h % 2 == 0) y else -y;
        return u + v;
    }

    pub fn noise(self: @This(), x: f32, y: f32) f32 {
        // Find enclosing unit grid coordinates
        const X: usize = @as(usize, @intFromFloat(@floor(x))) & 255;
        const Y: usize = @as(usize, @intFromFloat(@floor(y))) & 255;

        // Find relative fractional coordinates inside the cell
        const xf = x - @floor(x);
        const yf = y - @floor(y);

        // Compute fade curves for x and y
        const u = _fade(xf);
        const v = _fade(yf);

        // Hash coordinates of the 4 corners
        const p = self.permutation;
        const aa = p[(p[X] + Y) % 256];
        const ab = p[(p[X] + Y + 1) % 256];
        const ba = p[(p[X + 1] + Y) % 256];
        const bb = p[(p[X + 1] + Y + 1) % 256];

        // Calculate dot products from the 4 corners
        const x1 = _lerp(u, _grad(aa, xf, yf), _grad(ba, xf - 1, yf));
        const x2 = _lerp(u, _grad(ab, xf, yf - 1), _grad(bb, xf - 1, yf - 1));

        // Blend the results together
        return _lerp(v, x1, x2);
    }
};
