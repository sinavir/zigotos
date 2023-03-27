const fmt = @import("std").fmt;
const mem = @import("std").mem;
const Writer = @import("std").io.Writer;

const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;
const VGA_SIZE = VGA_WIDTH * VGA_HEIGHT;

pub const ConsoleColors = enum(u4) {
    Black = 0,
    Blue = 1,
    Green = 2,
    Cyan = 3,
    Red = 4,
    Magenta = 5,
    Brown = 6,
    LightGray = 7,
    DarkGray = 8,
    LightBlue = 9,
    LightGreen = 10,
    LightCyan = 11,
    LightRed = 12,
    LightMagenta = 13,
    LightBrown = 14,
    White = 15,
};

const VgaColor = packed struct {
    fg: ConsoleColors,
    bg: ConsoleColors,
};

const VgaEntry = packed struct {
    char: u8,
    color: VgaColor,
};

var row: usize = 0;
var column: usize = 0;

pub var color = VgaColor{ .fg = ConsoleColors.White, .bg = ConsoleColors.Black };

var buffer = @intToPtr([*]volatile VgaEntry, 0xb8000);

pub fn initialize() void {
    clear();
}

pub fn clear() void {
    const slice = buffer[0..VGA_SIZE];
    const value = VgaEntry{ .char = ' ', .color = color };
    for (slice) |*d| {
        d.* = value;
    }
}

pub fn putCharAt(c: u8, x: usize, y: usize) void {
    const index = y * VGA_WIDTH + x;
    buffer[index] = VgaEntry{ .char = c, .color = color };
}

pub fn putChar(c: u8) void {
    switch (c) {
        '\n' => {
            newline();
        },
        else => {
            putCharAt(c, column, row);
            column += 1;
            if (column == VGA_WIDTH) newline();
        },
    }
}

pub fn puts(data: []const u8) void {
    for (data) |c|
        putChar(c);
}

pub fn newline() void {
    column = 0;
    row += 1;
    if (row == VGA_HEIGHT)
        row = 0;
}

pub const writer = Writer(void, error{}, callback){ .context = {} };

fn callback(_: void, string: []const u8) error{}!usize {
    puts(string);
    return string.len;
}

pub fn printf(comptime format: []const u8, args: anytype) void {
    fmt.format(writer, format, args) catch unreachable;
}
