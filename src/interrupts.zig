const serial = @import("io/serial.zig");

const IDTR = packed struct {
    size: u16,
    address: u64,
};

const GateType = enum(u4) {
    INTERRUPT = 0xE,
    TRAP_GATE = 0xF,
    _,
};

pub const GateDescriptor = packed struct {
    offset1: u16,
    segment_selector: u16,
    ist: u3 = 0,
    _reserved1: u5,
    gate_type: GateType,
    _mbz1: u1 = 0,
    dpl: u2, //A 2-bit value which defines the CPU Privilege Levels which are
    //         allowed to access this interrupt via the INT instruction.
    //         Hardware interrupts ignore this mechanism.
    present: bool,
    offset2: u16,
    offset3: u32,
    _reserved2: u32,

    const Self = @This();

    pub fn getOffset(s: *Self) u64 {
        return @as(u64, s.offset3) << 32 + @as(u64, s.offset2) << 16 + @as(u64, s.offset1);
    }

    pub fn create(handler: *const fn () callconv(.Naked) noreturn, gate_type: GateType, present: bool, ss: u16) Self {
        const handler_ptr: usize = @ptrToInt(handler);
        return Self{
            .offset1 = @truncate(u16, handler_ptr),
            .segment_selector = ss,
            .ist = 0,
            ._reserved1 = 0,
            .gate_type = gate_type,
            ._mbz1 = 0,
            .dpl = 0,
            .present = present,
            .offset2 = @truncate(u16, handler_ptr >> 16),
            .offset3 = @truncate(u32, handler_ptr >> 32),
            ._reserved2 = 0,
        };
    }
};

fn sidt() IDTR {
    var idtr = IDTR{ .size = undefined, .address = undefined };
    asm volatile ("sidt %[idtr]"
        : [idtr] "=m" (idtr),
    );
    return idtr;
}

pub var idt: [256]GateDescriptor align(0x10) = undefined;

pub fn init() void {
    for (idt) |*idt_entry| {
        idt_entry.* = GateDescriptor.create(stop_handler, GateType.INTERRUPT, true, 0x8);
    }
    const idtr = IDTR{
        .size = @sizeOf(GateDescriptor) * idt.len,
        .address = @ptrToInt(&idt),
    };
    const idtr_ptr = @ptrToInt(&idtr);
    asm volatile ("lidt (%[idtr]); sti"
        :
        : [idtr] "r" (idtr_ptr),
    );
}
fn stop_handler() callconv(.Naked) noreturn {
    serial.puts("::::> CPU interrupt occupred");
    while (true) {}
}
