pub const BOOTBOOT_MAGIC = "BOOT";

// default virtual addresses for level 0 and 1 static loaders
pub const BOOTBOOT_MMIO = 0xfffffffff8000000; // memory mapped IO virtual address
pub const BOOTBOOT_FB = 0xfffffffffc000000; // frame buffer virtual address
pub const BOOTBOOT_INFO = 0xffffffffffe00000; // bootboot struct virtual address
pub const BOOTBOOT_ENV = 0xffffffffffe01000; // environment string virtual address
pub const BOOTBOOT_CORE = 0xffffffffffe02000; // core loadable segment start

// minimum protocol level:
// hardcoded kernel name, static kernel memory addresses
pub const PROTOCOL_MINIMAL = 0;
// static protocol level:
// kernel name parsed from environment, static kernel memory addresses
pub const PROTOCOL_STATIC = 1;
// dynamic protocol level:
// kernel name parsed, kernel memory addresses from ELF or PE symbols
pub const PROTOCOL_DYNAMIC = 2;
// big-endian flag
pub const PROTOCOL_BIGENDIAN = 0x80;

// loader types, just informational
pub const LOADER_BIOS = 0 << 2;
pub const LOADER_UEFI = 1 << 2;
pub const LOADER_RPI = 2 << 2;
pub const LOADER_COREBOOT = 3 << 2;

// framebuffer pixel format, only 32 bits supported
pub const FramebufferFormat = enum(u8) {
    ARGB = 0,
    RGBA = 1,
    ABGR = 2,
    BGRA = 3,
};

// mmap entry, type is stored in least significant tetrad (half byte) of size
// this means size described in 16 byte units (not a problem, most modern
// firmware report memory in pages, 4096 byte units anyway).
pub const MMapEnt = extern struct {
    ptr: u64 align(1),
    size: u64 align(1),

    const Self = @This();

    pub inline fn getPtr(self: *Self) u64 {
        return self.ptr;
    }

    pub inline fn getSizeInBytes(self: *const Self) u64 {
        return self.size & 0xFFFFFFFFFFFFFFF0;
    }

    pub inline fn getSizeIn4KiBPages(self: *Self) u64 {
        return self.getSizeInBytes() / 4096;
    }

    pub inline fn getType(self: *const Self) MMapType {
        return @intToEnum(MMapType, @truncate(u4, self.size));
    }

    pub inline fn isFree(self: *const Self) bool {
        return self.getType() == MMapType.MMAP_FREE;
    }
};

pub const MMapType = enum(u4) {
    /// don't use. Reserved or unknown regions
    MMAP_USED = 0,

    /// usable memory
    MMAP_FREE = 1,

    /// acpi memory, volatile and non-volatile as well
    MMAP_ACPI = 2,

    /// memory mapped IO region
    MMAP_MMIO = 3,
};

pub const INITRD_MAXSIZE = 16; // Mb

pub const BOOTBOOT = extern struct {
    //Platform independent
    magic: [4]u8 align(1),
    size: u32 align(1),
    protocol: u8 align(1),
    fb_type: FramebufferFormat align(1),
    numcores: u16 align(1),
    bspid: u16 align(1),
    timezone: i16 align(1),
    datetime: [8]u8 align(1),
    initrd_ptr: u64 align(1),
    initrd_size: u64 align(1),
    fb_ptr: u64 align(1),
    fb_size: u32 align(1),
    fb_width: u32 align(1),
    fb_height: u32 align(1),
    fb_scanline: u32 align(1),

    acpi_ptr: u64 align(1),
    smbi_ptr: u64 align(1),
    efi_ptr: u64 align(1),
    mp_ptr: u64 align(1),
    unused0: u64 align(1),
    unused1: u64 align(1),
    unused2: u64 align(1),
    unused3: u64 align(1),
};

pub extern const boot_info: BOOTBOOT;
pub extern const environment: [4096]u8;

pub var m_map: []MMapEnt = undefined;
pub fn init_m_map() void {
    const m_map_size = (boot_info.size - @sizeOf(BOOTBOOT)) / @sizeOf(MMapEnt);
    m_map = @intToPtr([*]MMapEnt, @ptrToInt(&boot_info) + @sizeOf(BOOTBOOT))[0..m_map_size];
}
