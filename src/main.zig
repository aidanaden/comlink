const std = @import("std");
const comlink = @import("comlink.zig");
const vaxis = @import("vaxis");

const log = std.log.scoped(.comlink);

pub const panic = vaxis.panic_handler;

pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            std.log.err("memory leak", .{});
        }
    }
    const alloc = gpa.allocator();

    var env = try std.process.getEnvMap(alloc);
    defer env.deinit();

    var app = try comlink.App.init(alloc);
    defer app.deinit();
    app.run() catch |err| {
        switch (err) {
            // ziglua errors
            error.LuaError => {
                const msg = app.lua.toString(-1) catch "";
                const duped = app.alloc.dupe(u8, msg) catch "";
                defer app.alloc.free(duped);

                app.deinit();
                log.err("{s}", .{duped});

                return 101; // 101 is a lua error
            },
            else => return err,
        }
    };
    return 0;
}

test {
    _ = @import("irc.zig");
}
