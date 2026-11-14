# NixOS module: name one application per class ("my image viewer is X")
# and get the system-wide default for every MIME type of that class.
#
# The result is written through the stock `xdg.mime.defaultApplications`
# option, i.e. to /etc/xdg/mimeapps.list. A user's own
# ~/.config/mimeapps.list keeps precedence over it.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  mimeLib = import ../lib { inherit lib; };
  cfg = config.mimetypeDefaults;

  resolved = mimeLib.resolve { inherit (cfg) apps classes associations; };

  mimeType = lib.types.strMatching "[^/[:space:]]+/[^/[:space:]]+";

  application = lib.types.either lib.types.str (lib.types.listOf lib.types.str);

  # desktop file name -> the classes / MIME types that name it
  references = lib.zipAttrs (
    lib.concatLists (
      lib.mapAttrsToList (
        name: app:
        lib.optionals (app != null && cfg.classes ? ${name}) (
          map (id: { ${id} = "apps.${name}"; }) (mimeLib.normalizeApp app)
        )
      ) cfg.apps
      ++ lib.mapAttrsToList (
        type: app: map (id: { ${id} = "associations.\"${type}\""; }) (mimeLib.normalizeApp app)
      ) cfg.associations
    )
  );
in
{
  options.mimetypeDefaults = {
    apps = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr application);
      default = { };
      example = lib.literalExpression ''
        {
          webBrowser = "firefox";
          pdfViewer = "org.pwmt.zathura";
          imageViewer = "imv";
          textEditor = [ "code" "nvim" ];
        }
      '';
      description = ''
        The default application per class. A class is a name from
        {option}`mimetypeDefaults.classes`; the application is the name of
        its desktop file (the `.desktop` suffix is optional), or a list of
        desktop files in order of preference. `null` leaves a class alone.
      '';
    };

    classes = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            description = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "What the class is for.";
            };
            mimeTypes = lib.mkOption {
              type = lib.types.listOf mimeType;
              default = [ ];
              description = ''
                MIME types of this class. Definitions are concatenated, so
                setting this for a built-in class adds to its list; use
                `lib.mkForce` to replace the list.
              '';
            };
            excludeMimeTypes = lib.mkOption {
              type = lib.types.listOf mimeType;
              default = [ ];
              description = "MIME types to drop from this class.";
            };
          };
        }
      );
      example = lib.literalExpression ''
        {
          # extend a built-in class
          imageViewer.mimeTypes = [ "image/x-farbfeld" ];
          # take a type out of a built-in class
          textEditor.excludeMimeTypes = [ "application/json" ];
          # define a class of your own
          cadViewer.mimeTypes = [ "image/vnd.dwg" "image/vnd.dxf" ];
        }
      '';
      description = ''
        The application classes: which MIME types belong to which role.
        Pre-filled with the built-in classes (see the README); extend
        them, exclude types from them or add classes of your own.
      '';
    };

    associations = lib.mkOption {
      type = lib.types.attrsOf application;
      default = { };
      example = lib.literalExpression ''{ "image/svg+xml" = "org.inkscape.Inkscape"; }'';
      description = ''
        Defaults for single MIME types. They win over whatever a class
        says about the type.
      '';
    };

    check = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Fail the system build if a default names a desktop file that no
          installed package provides. Searched are the system profile and
          every `users.users.<name>.packages`.
        '';
      };
      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          Further packages to search for desktop files, for applications
          that are installed in a way the check cannot see.
        '';
      };
    };

    resolved = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      readOnly = true;
      description = "The resulting defaults: MIME type to desktop files. For inspection.";
    };
  };

  config = {
    mimetypeDefaults.classes = lib.mapAttrs (_: class: {
      description = lib.mkDefault class.description;
      inherit (class) mimeTypes;
    }) mimeLib.classes;

    mimetypeDefaults.resolved = resolved.associations;

    assertions = [
      {
        assertion = resolved.unknownClasses == [ ];
        message = ''
          mimetypeDefaults.apps names unknown class(es): ${lib.concatStringsSep ", " resolved.unknownClasses}
          Known classes: ${lib.concatStringsSep ", " (lib.attrNames cfg.classes)}
          Define a new class with mimetypeDefaults.classes.<name>.mimeTypes.
        '';
      }
      {
        assertion = resolved.conflicts == { };
        message = ''
          mimetypeDefaults: MIME types claimed by several classes with different applications:
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              type: names: "  ${type}: ${lib.concatStringsSep ", " names}"
            ) resolved.conflicts
          )}
          Settle each one with mimetypeDefaults.associations."<type>" or drop it
          from a class with mimetypeDefaults.classes.<name>.excludeMimeTypes.
        '';
      }
    ];

    # mkDefault: a direct xdg.mime.defaultApplications entry for the same
    # type still wins instead of colliding.
    xdg.mime.defaultApplications = lib.mapAttrs (_: lib.mkDefault) resolved.associations;

    system.checks = lib.optional (cfg.check.enable && references != { }) (
      import ../lib/check.nix { inherit lib pkgs; } {
        inherit references;
        packages = [
          config.system.path
        ]
        ++ lib.concatMap (user: user.packages) (lib.attrValues config.users.users)
        ++ cfg.check.extraPackages;
      }
    );
  };
}
