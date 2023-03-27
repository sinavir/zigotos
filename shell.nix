{ pkgs ? (import ./nix/nixpkgs.nix { }) }:
pkgs.mkShell {
  packages = [
    pkgs.zig
    pkgs.gdb
    pkgs.qemu
    pkgs.grub2
    pkgs.libisoburn
  ];
}
