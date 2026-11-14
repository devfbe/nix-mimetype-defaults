# Pure functions and data, independent of NixOS. `lib` is nixpkgs' lib.
{ lib }:
let
  classes = import ./classes.nix;

  # "imv" and "imv.desktop" both name the desktop file imv.desktop.
  toDesktopId = id: if lib.hasSuffix ".desktop" id then id else "${id}.desktop";

  # An application is one desktop file or a list of them in order of
  # preference (the first installed one wins).
  normalizeApp = app: map toDesktopId (lib.toList app);

  # The MIME types a class finally covers.
  classMimeTypes =
    class: lib.subtractLists (class.excludeMimeTypes or [ ]) (lib.unique class.mimeTypes);

  # Turn "class -> application" into "MIME type -> desktop files".
  #
  #   apps          class name -> application (null = leave the class alone)
  #   classes       class name -> { mimeTypes; excludeMimeTypes ? [ ]; }
  #   associations  MIME type -> application, wins over every class
  #
  # Returns the associations plus everything that is wrong with the input,
  # so the caller decides how to report it:
  #   unknownClasses  names in `apps` that are no class
  #   conflicts       MIME type -> the classes that claim it with different
  #                   applications (and no `associations` entry settles it)
  resolve =
    {
      apps ? { },
      classes ? import ./classes.nix,
      associations ? { },
    }:
    let
      assigned = lib.mapAttrs (_: normalizeApp) (lib.filterAttrs (_: app: app != null) apps);
      unknownClasses = lib.filter (name: !(classes ? ${name})) (lib.attrNames assigned);
      known = removeAttrs assigned unknownClasses;

      # MIME type -> [ class names claiming it ]
      claims = lib.zipAttrs (
        lib.concatMap (name: map (type: { ${type} = name; }) (classMimeTypes classes.${name})) (
          lib.attrNames known
        )
      );

      conflicts = lib.filterAttrs (
        type: names: !(associations ? ${type}) && lib.length (lib.unique (map (n: known.${n}) names)) > 1
      ) claims;

      fromClasses = lib.mapAttrs (_: names: known.${lib.head names}) claims;
      explicit = lib.mapAttrs (_: normalizeApp) associations;
    in
    {
      associations = fromClasses // explicit;
      inherit unknownClasses conflicts;
    };

  # Like `resolve`, but returns the associations only and throws on any
  # problem. For use outside the module system.
  mkAssociations =
    args:
    let
      r = resolve args;
    in
    if r.unknownClasses != [ ] then
      throw "mimetype-defaults: unknown application class(es): ${lib.concatStringsSep ", " r.unknownClasses}"
    else if r.conflicts != { } then
      throw "mimetype-defaults: MIME types claimed by several classes with different applications: ${
        lib.concatStringsSep ", " (
          lib.mapAttrsToList (type: names: "${type} (${lib.concatStringsSep ", " names})") r.conflicts
        )
      }"
    else
      r.associations;

  # The text of a mimeapps.list that sets these defaults.
  toMimeAppsList =
    associations:
    "[Default Applications]\n"
    + lib.concatStrings (
      lib.mapAttrsToList (type: ids: "${type}=${lib.concatStringsSep ";" ids};\n") associations
    );
in
{
  inherit
    classes
    toDesktopId
    normalizeApp
    classMimeTypes
    resolve
    mkAssociations
    toMimeAppsList
    ;
}
