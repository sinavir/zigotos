const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    var target = std.zig.CrossTarget{
        .os_tag = .freestanding,
        .cpu_arch = .x86_64,
        .abi = .none,
    };

    const mode = b.standardReleaseOptions();
    const kernel = b.addExecutable("zigotos.elf", "src/main.zig");
    kernel.setLinkerScriptPath(.{ .path = "src/link.ld" });
    kernel.code_model = .kernel;
    kernel.setTarget(target);
    kernel.setBuildMode(mode);
    kernel.install();
    kernel.strip = true;

    const kernel_step = b.step("kernel", "Build the kernel");
    kernel_step.dependOn(&kernel.install_step.?.step);

    const iso_dir = b.fmt("{s}/initrd", .{b.cache_root});
    const iso_out_path = b.fmt("{s}/disk.iso", .{b.exe_dir});

    const kernel_path = b.getInstallPath(
        kernel.install_step.?.dest_dir,
        kernel.out_filename,
    );

    const iso_cmd_str = &[_][]const u8{
        "/bin/sh",
        "-c",
        std.mem.concat(b.allocator, u8, &[_][]const u8{
            "rm -rf ",
            iso_dir,
            " && ",
            "mkdir -p ",
            iso_dir,
            " && ",
            "cp ",
            kernel_path,
            " ",
            iso_dir,
            " && ",
            "mkbootimg boot_config.json ",
            iso_out_path,
        }) catch unreachable,
    };

    const iso_cmd = b.addSystemCommand(iso_cmd_str);
    iso_cmd.step.dependOn(kernel_step);

    const iso_step = b.step("bootable", "Build a bootable disk image");
    iso_step.dependOn(&iso_cmd.step);
    b.default_step.dependOn(iso_step);

    const run_cmd_str = &[_][]const u8{
        "qemu-system-x86_64",
        "-cdrom",
        iso_out_path,
        "-serial",
        "stdio",
        "-m",
        "4G",
    };

    const run_cmd = b.addSystemCommand(run_cmd_str);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the kernel");
    run_step.dependOn(&run_cmd.step);
    kernel.strip = true;
}
