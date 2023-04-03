{ pkgs ? (import ./nix/nixpkgs.nix { }) }:
pkgs.mkShell {
  packages = [
    pkgs.zig
    pkgs.gdb
    pkgs.qemu
    (pkgs.callPackage ./nix/bootboot.nix {})
  ];
}
