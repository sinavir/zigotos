const serial = @import("io/serial.zig");

const GDTR = packed struct {
    size: u16,
    address: [*]SegmentDescriptor,
};

pub const SegmentSelector = packed struct {
    rpl: u2,
    ti: u1 = 0,
    si: u13,
};

pub const SegmentDescriptor = packed struct {
    limit1: u16,
    address1: u16,
    address2: u8,
    access: u8,
    limit2: u4,
    flags: u4,
    address3: u8,

    const Self = @This();

    pub fn create(address: u32, limit: u20, access: u8, flags: u4) Self {
        return Self{
            .address1 = @truncate(u16, address),
            .address2 = @truncate(u8, address >> 16),
            .address3 = @truncate(u8, address >> 24),
            .limit1 = @truncate(u16, limit),
            .limit2 = @truncate(u4, limit >> 16),
            .access = access,
            .flags = flags,
        };
    }
    pub fn createHighTSS(address: u64) Self {
        return Self{
            .address1 = @truncate(u16, address >> 48),
            .limit1 = @truncate(u16, address >> 32),
            .address2 = 0,
            .address3 = 0,
            .limit2 = 0,
            .access = 0,
            .flags = 0,
        };
    }
};

fn sgdt() GDTR {
    var gdtr = GDTR{ .size = undefined, .address = undefined };
    asm volatile ("sgdt %[gdtr]"
        : [gdtr] "=m" (gdtr),
    );
    return gdtr;
}

pub var gdt: [7]SegmentDescriptor align(0x10) = [_]SegmentDescriptor{
    SegmentDescriptor.create(0, 0, 0, 0),
    SegmentDescriptor.create(0, 0xfffff, 0x9a, 0xa),
    SegmentDescriptor.create(0, 0xfffff, 0x92, 0xc),
    SegmentDescriptor.create(0, 0xfffff, 0xfa, 0xa),
    SegmentDescriptor.create(0, 0xfffff, 0xf2, 0xc),
    undefined,
    undefined,
};

const TSS = packed struct { reserved0: u32 = 0, rsp0: usize = 0, rsp1: usize = 0, rsp2: usize = 0, reserved1: u64 = 0, ist1: usize = 0, ist2: usize = 0, ist3: usize = 0, ist4: usize = 0, ist5: usize = 0, ist6: usize = 0, ist7: usize = 0, reserved2: u64 = 0, reserved3: u16 = 0, iopb_offset: u16 = 0 };

pub var tss align(0x10) = TSS{};

pub fn init() void {
    //TODO Remove this ugly truncate
    gdt[5] = SegmentDescriptor.create(@truncate(u32, @ptrToInt(&tss)), @sizeOf(TSS), 0x89, 0);
    gdt[6] = SegmentDescriptor.createHighTSS(@ptrToInt(&tss));
    const gdtr = GDTR{
        .size = @sizeOf(SegmentDescriptor) * gdt.len,
        .address = &gdt,
    };
    const gdtr_ptr = &gdtr;
    asm volatile ("lgdt (%[gdtr])"
        :
        : [gdtr] "r" (gdtr_ptr),
    );
}
