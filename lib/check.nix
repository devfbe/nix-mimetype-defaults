# Build-time check: every desktop file a default points at must be
# installed. A misspelled desktop file name is not an error for the
# desktop — the default is silently ignored — so it is made one here.
{ lib, pkgs }:
{
  # desktop file name -> where the configuration names it (for the message)
  references,
  # packages whose share/applications are searched
  packages,
}:
pkgs.runCommand "mimetype-defaults-check"
  {
    references = pkgs.writeText "mimetype-defaults-references" (
      lib.concatStrings (
        lib.mapAttrsToList (id: sources: "${id}\t${lib.concatStringsSep ", " sources}\n") references
      )
    );
    inherit packages;
  }
  ''
    # A desktop file ID is its path below share/applications with "/"
    # replaced by "-" (kde/okular.desktop -> kde-okular.desktop).
    for package in $packages; do
      dir=$package/share/applications
      [ -d "$dir" ] || continue
      (cd "$dir" && find -L . -name '*.desktop' -printf '%P\n') | tr / -
    done | sort -u > available

    failed=
    while IFS=$'\t' read -r id sources; do
      grep -Fxq -- "$id" available && continue
      failed=1
      echo "mimetype-defaults: no installed package provides '$id' (set for: $sources)"
      stem=''${id%.desktop}
      similar=$(grep -iF -- "''${stem##*.}" available | head -n 5 | tr '\n' ' ' || true)
      [ -z "$similar" ] || echo "  installed desktop files with a similar name: $similar"
    done < "$references"

    if [ -n "$failed" ]; then
      echo "Fix the name, install the application system-wide or through"
      echo "users.users.<name>.packages, or name its package in"
      echo "mimetypeDefaults.check.extraPackages. To skip this check entirely"
      echo "(e.g. for Flatpak applications): mimetypeDefaults.check.enable = false."
      exit 1
    fi
    touch $out
  ''
