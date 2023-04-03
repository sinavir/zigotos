const std = @import("std");

const bootboot = @import("bootboot.zig");

const console = @import("io/console.zig");
const serial = @import("io/serial.zig");

// Entry point, called by BOOTBOOT Loader
export fn _start() callconv(.Naked) noreturn {
    console.init();
    serial.puts("Hello world !");
    while (true) {}
}

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    for ("PANIC /!\\") |i, idx| console.putCharAt(idx * 8, 0, i);
    for (msg) |i, idx| console.putCharAt(idx * 8, 16, i);
    while (true) {}
}
