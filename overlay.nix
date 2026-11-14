# Overlay: the class data and helpers as `pkgs.mimetypeDefaults`, for use
# outside the NixOS module (home-manager, a wrapper script, a container).
final: _prev:
let
  mimeLib = import ./lib { inherit (final) lib; };
in
{
  mimetypeDefaults = mimeLib // {
    # A mimeapps.list file from the same arguments as `mkAssociations`:
    #   pkgs.mimetypeDefaults.mkMimeAppsList { apps.imageViewer = "imv"; }
    mkMimeAppsList =
      args: final.writeText "mimeapps.list" (mimeLib.toMimeAppsList (mimeLib.mkAssociations args));
  };
}
