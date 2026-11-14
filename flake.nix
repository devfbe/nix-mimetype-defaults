{
  description = "Default applications for NixOS by role: name your image viewer, text editor and PDF viewer once";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      lib = import ./lib { inherit (nixpkgs) lib; };

      nixosModules.default = ./modules/nixos.nix;

      overlays.default = import ./overlay.nix;

      checks = forAllSystems (
        system:
        import ./tests {
          inherit self nixpkgs system;
        }
      );
    };
}
