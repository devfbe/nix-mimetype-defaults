# Entry point without flakes:
#   let mimetypeDefaults = import (fetchTarball "https://github.com/devfbe/nix-mimetype-defaults/archive/main.tar.gz");
#   in { imports = [ mimetypeDefaults.nixosModules.default ]; }
{
  nixosModules.default = ./modules/nixos.nix;
  overlays.default = import ./overlay.nix;
}
