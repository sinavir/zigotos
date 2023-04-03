const bootboot = @import("../bootboot.zig");
const io = @import("io.zig");

const SERIAL_PORT: u16 = 0x3f8;

pub inline fn putc(c: u8) void {
    io.out(SERIAL_PORT, c);
}

pub fn puts(s: []const u8) void {
    for (s) |c| putc(c);
}
