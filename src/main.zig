const console = @import("console.zig");
const std = @import("std");

const ALIGN = 1 << 0;
const MEMINFO = 1 << 1;
const MAGIC = 0x1BADB002;
const FLAGS = ALIGN | MEMINFO;

const MultibootHeader = extern struct {
    magic: i32 = MAGIC,
    flags: i32,
    checksum: i32,
};

pub export var multiboot align(4) linksection(".text.multiboot") = MultibootHeader{
    .flags = FLAGS,
    .checksum = -(MAGIC + FLAGS),
};

export var stack_bytes: [16 * 8192]u8 align(16) linksection(".bss") = undefined;

export fn kmain() callconv(.C) noreturn {
    console.puts("Hello world!\nWelcome to zigotos");
    while (true) {}
}

pub fn panic(message: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    console.puts(message);
    while (true) {}
}
