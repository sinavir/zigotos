const std = @import("std");

const bootboot = @import("bootboot.zig");

const console = @import("console.zig");

// Entry point, called by BOOTBOOT Loader
export fn _start() callconv(.Naked) noreturn {
    console.init();
    var i: u16 = 0;
    var j: u16 = 0;
    while (j < 26 * 6) : (j += 1) {
        console.putCharAt(j * 8, i * 16, 'A' + @truncate(u8, (i + j) % 26));
    }
    while (true) {}
}

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    for (msg) |i, idx| console.putCharAt(idx * 8, 0, i);
    while (true) {}
}
