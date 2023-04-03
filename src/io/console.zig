//   console.zig -- screen driver
//
//   Handles all screen drawing stuff but not terminal management

const bootboot = @import("../bootboot.zig");
const std = @import("std");

const PsfHeader = packed struct {
    magic: u32, // magic bytes to identify PSF
    version: u32, // zero
    headersize: u32, // offset of bitmaps in file, 32
    flags: u32, // 0 if there's no unicode table
    numglyph: u32, // number of glyphs
    bytesperglyph: u32, // size of each glyph
    height: u32, // height in pixels
    width: u32, // width in pixels
};

fn getGlyphs(comptime path: []const u8) Fontspec {
    const fontEmbedded = @embedFile(path);
    const header = @bitCast(PsfHeader, fontEmbedded[0..@sizeOf(PsfHeader)].*);
    if (header.magic != 0x864ab572) unreachable;
    const bytes_per_line = (header.width + 7) / 8;
    const gw = header.width;
    const gh = header.height;
    var glyphs = fontEmbedded[header.headersize..(header.headersize + header.numglyph * header.bytesperglyph)];
    return Fontspec{
        .glyphs = glyphs,
        .gw = gw,
        .gh = gh,
        .bytes_per_line = bytes_per_line,
        .bytes_per_glyph = header.bytesperglyph,
        .num_glyphs = header.numglyph,
    };
}

const Fontspec = struct {
    glyphs: []const u8,
    gw: usize,
    gh: usize,
    num_glyphs: usize,
    bytes_per_glyph: usize,
    bytes_per_line: usize,
};

const Pixel = packed struct {
    blue: u8,
    green: u8,
    red: u8,
    alpha: u8 = 0,
    const WHITE = Pixel{
        .red = 0xff,
        .green = 0xff,
        .blue = 0xff,
    };
    const BLACK = Pixel{
        .red = 0x00,
        .green = 0x00,
        .blue = 0x00,
    };
};

const font = getGlyphs("font.psf");

extern var fb: u8;
pub var framebuffer: []Pixel = undefined;
var boot_info: bootboot.BOOTBOOT = undefined;
var scanline: u32 = undefined;

// init console
pub fn init() void {
    boot_info = bootboot.boot_info;
    if (boot_info.fb_type != bootboot.FramebufferFormat.ARGB) std.debug.panic("Invalid frame buffer format {any}", .{boot_info.fb_type});

    framebuffer = @intToPtr([*]Pixel, @ptrToInt(&fb))[0..boot_info.fb_size];
    scanline = boot_info.fb_scanline / 4; // fb_scanline is a byte offset. We want 32bits offsets
}

pub fn putCharAt(x: usize, y: usize, c: u8) void {
    if (c > 0 and c < font.num_glyphs) {
        const char_offset = c * font.bytes_per_glyph;
        var i: usize = 0;
        var j: usize = undefined;
        const buf_offset = x + scanline * y;
        var mask: u8 = undefined;
        var offset: u32 = 0;
        while (i < font.gh) : (i += 1) {
            j = 0;
            mask = 0x80;
            while (j < font.gw) : (j += 1) {
                framebuffer[buf_offset + i * scanline + j] = if (font.glyphs[char_offset + offset] & mask == 0) Pixel.BLACK else Pixel.WHITE;
                mask >>= 1;
                if (mask == 0) {
                    offset += 1;
                    mask = 0x80;
                }
            }
            if (mask != 0x80) offset += 1;
        }
    }
}

pub fn scroll(y_scroll: usize) void {
    var delta = scanline * y_scroll;
    for (framebuffer[0..(boot_info.fb_width * boot_info.fb_height - delta)]) |*d, idx| d.* = framebuffer[idx + delta];
}
