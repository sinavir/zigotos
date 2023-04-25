pub const ControlReg = enum {
    CR0,
    CR2,
    CR3,
    CR4,
    CR8,

    pub fn get(r: ControlReg) usize {
        switch (r) {
            ControlReg.CR0 => return asm volatile ("movq %cr0, %[r]"
                : [r] "=r" (-> usize),
            ),
            ControlReg.CR2 => return asm volatile ("movq %cr2, %[r]"
                : [r] "=r" (-> usize),
            ),
            ControlReg.CR3 => return asm volatile ("movq %cr3, %[r]"
                : [r] "=r" (-> usize),
            ),
            ControlReg.CR4 => return asm volatile ("movq %cr4, %[r]"
                : [r] "=r" (-> usize),
            ),
            ControlReg.CR8 => return asm volatile ("movq %cr8, %[r]"
                : [r] "=r" (-> usize),
            ),
        }
    }
};

pub const PhysicalAddress = u52;

pub fn getCR3TableAddress(cr3: usize) PhysicalAddress {
    return @truncate(PhysicalAddress, cr3 & 0xffffffffff000);
}
