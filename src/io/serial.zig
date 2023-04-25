const bootboot = @import("../bootboot.zig");
const io = @import("io.zig");
const Writer = @import("std").io.Writer;

const SERIAL_PORT: u16 = 0x3f8;

pub inline fn putc(c: u8) void {
    io.out(SERIAL_PORT, c);
}

pub fn puts(s: []const u8) void {
    for (s) |c| putc(c);
}

pub const writer = Writer(void, error{}, callback){ .context = {} };

fn callback(_: void, s: []const u8) error{}!usize {
    puts(s);
    return s.len;
}
