const std = @import("std");
var template_zon = @import("_build.zig.zon");
var project_zon = @import("build.zig.zon");

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [1024]u8 = undefined;
    const stdout_file = std.Io.File.stdout();
    var stdout_file_writer = stdout_file.writer(init.io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;

    var serializer = std.zon.Serializer{ .writer = stdout };
    var s = try serializer.beginStruct(.{});
    inline for (std.meta.fields(@TypeOf(template_zon))) |field| {
        if (std.mem.eql(u8, field.name, "name") or std.mem.eql(u8, field.name, "fingerprint")) {
            try s.field(field.name, @field(project_zon, field.name), .{});
        } else {
            try s.field(field.name, @field(template_zon, field.name), .{});
        }
    }
    try s.end();

    try stdout.flush();
}
