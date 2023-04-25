const std = @import("std");

const bootboot = @import("bootboot.zig");

const console = @import("io/console.zig");
const serial = @import("io/serial.zig");
const mem = @import("mem.zig");
const interrupts = @import("interrupts.zig");
const gdt = @import("gdt.zig");

// Entry point, called by BOOTBOOT Loader
export fn _start() callconv(.Naked) noreturn {
    serial.puts("Zigotos is booting !\n");
    serial.puts("Initializing GDT ...");
    gdt.init();
    serial.puts("Done\n");
    serial.puts("Initializing IDT ...");
    interrupts.init();
    serial.puts("Done\n");
    serial.puts("Initializing Console ...");
    console.init();
    serial.puts("Done\n");
    serial.puts("Initializing Memory map ...");
    bootboot.init_m_map();
    serial.puts("Done\n");
    serial.puts("\n");
    serial.puts("Calling kmain\n");
    kmain() catch |err| std.debug.panic("Fatal error {any}", .{err});
    serial.puts("\nkmain exited successfully, hanging\n");
    while (true) {}
}

fn kmain() anyerror!void {
    const cr3 = mem.reg.ControlReg.CR3.get();
    const PML4 = @intToPtr(mem.paging.PageTable, mem.reg.getCR3TableAddress(cr3));
    try inspectPage(PML4, 4, 0x0);
    var s: u64 = 0;
    printStackPointer();
    for (bootboot.m_map) |mmap_ent| {
        if (mmap_ent.isFree()) s += mmap_ent.size;
        try serial.writer.print("Memory {}: [0x{x:0>16}-0x{x:0>16}]\n", .{ mmap_ent.getType(), mmap_ent.ptr, mmap_ent.ptr + mmap_ent.getSizeInBytes() });
    }
    try serial.writer.print("Total size of free memory: {x}\n", .{s});
    try serial.writer.print("Initrd at: [0x{x:0>16}-0x{x:0>16}]\n", .{ bootboot.boot_info.initrd_ptr, bootboot.boot_info.initrd_ptr + bootboot.boot_info.initrd_size });
}

fn inspectPage(pt: mem.paging.PageTable, page_level: u6, address: u48) anyerror!void {
    if (page_level == 0) @import("std").debug.panic("page_level = 0", .{});
    for (pt) |entry, i| {
        if (entry.present) {
            const start = @as(u48, @truncate(u9, i)) << ((9 * page_level + 3));
            if (entry.isLastPage(page_level)) {
                const end = (@as(u48, @truncate(u9, i)) + 1) << (9 * page_level + 3);
                try serial.writer.print("{x:12} ===> 0x{x:12}-0x{x:12}\n", .{ address + start, start, end });
            } else {
                const next = @intToPtr(mem.paging.PageTable, entry.getNextPageAddress());
                try inspectPage(next, page_level - 1, address + start);
            }
        }
    }
}

fn printStackPointer() void {
    var rsp: usize = undefined;
    asm volatile ("movq %rsp, %[sp]"
        : [sp] "=r" (rsp),
    );
    serial.writer.print("RSP=0x{x}\n", .{rsp}) catch @import("std").debug.panic("Can't write RSP to serial", .{});
}

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    serial.puts("\n\n/!\\ Panic !");
    serial.puts(msg);
    while (true) {}
}
