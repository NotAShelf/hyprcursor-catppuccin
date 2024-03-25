{
  description = "Catppuccin Cursors for Hyprcursor";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      perSystem = {
        self',
        pkgs,
        ...
      }: {
        packages = {
          hyprcursor-catppuccin = pkgs.callPackage ./nix/package.nix {};
          default = self'.packages.hyprcursor-catppuccin;
        };
      };
    };
}
