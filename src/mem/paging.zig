const reg = @import("reg.zig");

pub const PageTableEntry = packed struct {
    present: bool,
    rw: bool,
    useraccess: bool,
    pwt: bool, //Page-Level Writethrough
    pcd: bool, //Page-Level Cache disable
    accessed: bool,
    dirty: bool,
    page_size: bool, //If this page is the last
    global: bool,
    info1: u3,
    next: u40,
    info2: u11,
    no_execute: bool,

    const Self = @This();

    pub fn getNextPageAddressSAFE(e: Self, page_level: u8) error{LastPage}!reg.PhysicalAddress {
        if (e.isLastPage(page_level)) return error.LastPage;
        return (@as(reg.PhysicalAddress, e.next) << 12);
    }

    pub fn getNextPageAddress(e: Self) reg.PhysicalAddress {
        return (@as(reg.PhysicalAddress, e.next) << 12);
    }

    // Retourne l'addresse physique pointée par cette page
    pub fn getPhysicalPage(e: Self, page_level: u8) error{ NotLastPage, InvalidPageLevel }!reg.PhysicalAddress {
        if (!e.isLastPage(page_level)) return error.NotLastPage;
        const all_one = ~@as(u52, 0);
        const mask = switch (page_level) {
            1 => all_one << 12,
            2 => all_one << 24,
            3 => all_one << 36,
            else => error.InvalidPageLevel,
        };
        return (@as(reg.PhysicalAddress, e.next_address) << 12) & mask;
    }

    pub fn to_bytes(e: Self) usize {
        return @bitCast(usize, e);
    }

    pub fn isLastPage(e: Self, page_level: u8) bool {
        return e.page_size or (page_level == 1);
    }
};

pub const PageTable = *[512]PageTableEntry;
