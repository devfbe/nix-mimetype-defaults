# Flake checks. Pure evaluation tests are wrapped in a trivial derivation
# so that `nix flake check` runs them.
{
  self,
  nixpkgs,
  system,
}:
let
  inherit (nixpkgs) lib;
  pkgs = nixpkgs.legacyPackages.${system};
  mimeLib = self.lib;

  # Fails at evaluation time, listing every failed case.
  evalTest =
    name: cases:
    let
      failures = lib.runTests cases;
    in
    if failures == [ ] then
      pkgs.runCommand "test-${name}" { } "touch $out"
    else
      throw "test ${name} failed:\n${lib.generators.toPretty { } failures}";

  nixos =
    module:
    (lib.nixosSystem {
      modules = [
        self.nixosModules.default
        {
          nixpkgs.hostPlatform = system;
          system.stateVersion = lib.trivial.release;
        }
        module
      ];
    }).config;

  # Only this module's assertions; a bare test system fails others
  # (no root file system, no boot loader).
  failedAssertions =
    config:
    map (a: a.message) (
      lib.filter (a: !a.assertion && lib.hasInfix "mimetypeDefaults" a.message) config.assertions
    );

  fakeApp =
    path:
    pkgs.writeTextDir "share/applications/${path}" ''
      [Desktop Entry]
      Type=Application
      Name=Fake
      Exec=true
    '';

  check = import ../lib/check.nix { inherit lib pkgs; };

  basic = nixos {
    mimetypeDefaults.apps = {
      pdfViewer = "zathura";
      imageViewer = [
        "imv.desktop"
        "gimp"
      ];
      rareImageViewer = null;
    };
  };
in
{
  lib = evalTest "lib" {
    testDesktopSuffixAdded = {
      expr = mimeLib.toDesktopId "imv";
      expected = "imv.desktop";
    };
    testDesktopSuffixKept = {
      expr = mimeLib.toDesktopId "org.gnome.Loupe.desktop";
      expected = "org.gnome.Loupe.desktop";
    };
    testClassBecomesAssociations = {
      expr = mimeLib.mkAssociations { apps.pdfViewer = "zathura"; };
      expected = {
        "application/pdf" = [ "zathura.desktop" ];
      };
    };
    testPreferenceList = {
      expr =
        (mimeLib.mkAssociations {
          apps.fileManager = [
            "pcmanfm-qt"
            "thunar.desktop"
          ];
        })."inode/directory";
      expected = [
        "pcmanfm-qt.desktop"
        "thunar.desktop"
      ];
    };
    testNullLeavesClassAlone = {
      expr = mimeLib.mkAssociations { apps.pdfViewer = null; };
      expected = { };
    };
    testExcludeMimeTypes = {
      expr = mimeLib.mkAssociations {
        apps.viewer = "v";
        classes.viewer = {
          mimeTypes = [
            "image/a"
            "image/b"
          ];
          excludeMimeTypes = [ "image/b" ];
        };
      };
      expected = {
        "image/a" = [ "v.desktop" ];
      };
    };
    testAssociationWinsOverClass = {
      expr =
        (mimeLib.mkAssociations {
          apps.imageViewer = "imv";
          associations."image/svg+xml" = "org.inkscape.Inkscape";
        })."image/svg+xml";
      expected = [ "org.inkscape.Inkscape.desktop" ];
    };
    testUnknownClassReported = {
      expr = (mimeLib.resolve { apps.imageViwer = "imv"; }).unknownClasses;
      expected = [ "imageViwer" ];
    };
    testUnknownClassThrows = {
      expr = (builtins.tryEval (mimeLib.mkAssociations { apps.imageViwer = "imv"; })).success;
      expected = false;
    };
    testConflictReported = {
      expr =
        (mimeLib.resolve {
          apps = {
            a = "one";
            b = "two";
          };
          classes = {
            a.mimeTypes = [ "image/x" ];
            b.mimeTypes = [ "image/x" ];
          };
        }).conflicts;
      expected = {
        "image/x" = [
          "a"
          "b"
        ];
      };
    };
    testSameAppIsNoConflict = {
      expr =
        (mimeLib.resolve {
          apps = {
            a = "one";
            b = "one";
          };
          classes = {
            a.mimeTypes = [ "image/x" ];
            b.mimeTypes = [ "image/x" ];
          };
        }).conflicts;
      expected = { };
    };
    testAssociationSettlesConflict = {
      expr =
        (mimeLib.resolve {
          apps = {
            a = "one";
            b = "two";
          };
          classes = {
            a.mimeTypes = [ "image/x" ];
            b.mimeTypes = [ "image/x" ];
          };
          associations."image/x" = "three";
        }).conflicts;
      expected = { };
    };
    testMimeAppsList = {
      expr = mimeLib.toMimeAppsList {
        "application/pdf" = [
          "a.desktop"
          "b.desktop"
        ];
      };
      expected = "[Default Applications]\napplication/pdf=a.desktop;b.desktop;\n";
    };
    # Built-in classes are disjoint: assigning every class a different
    # application must not produce a single conflict.
    testBuiltinClassesDisjoint = {
      expr = (mimeLib.resolve { apps = lib.mapAttrs (name: _: name) mimeLib.classes; }).conflicts;
      expected = { };
    };
  };

  # Every built-in MIME type is known to shared-mime-info, and an alias is
  # only listed together with its canonical name. `newerNames` are the
  # canonical names of a later shared-mime-info release, which an older
  # one does not know yet; their old names are listed next to them.
  classes-known =
    pkgs.runCommand "test-classes-known"
      {
        types = pkgs.writeText "types" (
          lib.concatStrings (
            lib.mapAttrsToList (
              name: class: lib.concatMapStrings (type: "${name}\t${type}\n") class.mimeTypes
            ) mimeLib.classes
          )
        );
        mime = "${pkgs.shared-mime-info}/share/mime";
        newerNames = [
          "audio/matroska"
          "video/matroska"
          "video/matroska-3d"
          "image/vnd.ms-dds"
          "text/vnd.typst"
          "text/x-shellscript"
        ];
      }
      ''
        failed=
        while IFS=$'\t' read -r class type; do
          case $type in x-scheme-handler/*) continue ;; esac
          grep -Fxq -- "$type" $mime/types && continue
          canonical=$(awk -v t="$type" '$1 == t { print $2 }' $mime/aliases)
          if [ -z "$canonical" ]; then
            case " $newerNames " in *" $type "*) continue ;; esac
            echo "$class: $type is unknown to shared-mime-info"; failed=1
          elif ! grep -Fxq -- "$class"$'\t'"$canonical" $types; then
            echo "$class: $type is an alias of $canonical, which is missing"; failed=1
          fi
        done < $types
        [ -z "$failed" ]
        touch $out
      '';

  # The README documents every built-in class.
  readme-lists-classes = pkgs.runCommand "test-readme-lists-classes" { } ''
    for class in ${lib.concatStringsSep " " (lib.attrNames mimeLib.classes)}; do
      grep -q "\`$class\`" ${../README.md} || { echo "README.md does not mention class $class"; exit 1; }
    done
    touch $out
  '';

  nixos-module = evalTest "nixos-module" {
    testWritesStockOption = {
      expr = basic.xdg.mime.defaultApplications."application/pdf";
      expected = "zathura.desktop";
    };
    testWholeClassCovered = {
      expr = lib.all (type: basic.mimetypeDefaults.resolved ? ${type}) mimeLib.classes.imageViewer.mimeTypes;
      expected = true;
    };
    testNullClassSetsNothing = {
      expr = basic.mimetypeDefaults.resolved ? "image/x-tga";
      expected = false;
    };
    testPreferenceListKept = {
      expr = basic.xdg.mime.defaultApplications."image/png";
      expected = "imv.desktop;gimp.desktop";
    };
    testNoFalseAssertion = {
      expr = failedAssertions basic;
      expected = [ ];
    };
    testNothingSetNothingWritten = {
      expr =
        let
          config = nixos { };
        in
        {
          defaults = config.xdg.mime.defaultApplications;
          checks = lib.filter (c: lib.hasInfix "mimetype-defaults" c.name) config.system.checks;
        };
      expected = {
        defaults = { };
        checks = [ ];
      };
    };
    testBuiltinClassExtended = {
      expr =
        (nixos {
          mimetypeDefaults.apps.imageViewer = "imv";
          mimetypeDefaults.classes.imageViewer.mimeTypes = [ "image/x-farbfeld" ];
        }).mimetypeDefaults.resolved."image/x-farbfeld";
      expected = [ "imv.desktop" ];
    };
    testBuiltinClassReplaced = {
      expr =
        (nixos {
          mimetypeDefaults.apps.imageViewer = "imv";
          mimetypeDefaults.classes.imageViewer.mimeTypes = lib.mkForce [ "image/png" ];
        }).mimetypeDefaults.resolved;
      expected = {
        "image/png" = [ "imv.desktop" ];
      };
    };
    testOwnClass = {
      expr =
        (nixos {
          mimetypeDefaults.apps.cadViewer = "librecad";
          mimetypeDefaults.classes.cadViewer.mimeTypes = [ "image/vnd.dwg" ];
        }).mimetypeDefaults.resolved;
      expected = {
        "image/vnd.dwg" = [ "librecad.desktop" ];
      };
    };
    testDirectStockOptionWins = {
      expr =
        (nixos {
          mimetypeDefaults.apps.pdfViewer = "zathura";
          xdg.mime.defaultApplications."application/pdf" = "firefox.desktop";
        }).xdg.mime.defaultApplications."application/pdf";
      expected = "firefox.desktop";
    };
    testUnknownClassAsserted = {
      expr = lib.length (failedAssertions (nixos {
        mimetypeDefaults.apps.imageViwer = "imv";
      }));
      expected = 1;
    };
    testConflictAsserted = {
      expr = lib.length (failedAssertions (nixos {
        mimetypeDefaults.apps = {
          imageViewer = "imv";
          photos = "gwenview";
        };
        mimetypeDefaults.classes.photos.mimeTypes = [ "image/jpeg" ];
      }));
      expected = 1;
    };
    testCheckSeesUserPackages = {
      expr =
        let
          config = nixos {
            mimetypeDefaults.apps.pdfViewer = "zathura";
            users.users.alice = {
              isNormalUser = true;
              packages = [ pkgs.hello ];
            };
          };
          own = lib.filter (c: lib.hasInfix "mimetype-defaults" c.name) config.system.checks;
        in
        lib.length own == 1 && lib.elem pkgs.hello (lib.head own).packages;
      expected = true;
    };
  };

  desktop-check-passes = check {
    references = {
      "imv.desktop" = [ "apps.imageViewer" ];
      "kde-okular.desktop" = [ "apps.pdfViewer" ];
    };
    packages = [
      (fakeApp "imv.desktop")
      (fakeApp "kde/okular.desktop")
      pkgs.hello
    ];
  };

  desktop-check-fails =
    pkgs.runCommand "test-desktop-check-fails"
      {
        failed = pkgs.testers.testBuildFailure (check {
          references."zathura.desktop" = [
            "apps.pdfViewer"
            "associations.\"image/vnd.djvu\""
          ];
          packages = [ (fakeApp "org.pwmt.zathura.desktop") ];
        });
      }
      ''
        grep -F "no installed package provides 'zathura.desktop' (set for: apps.pdfViewer, associations.\"image/vnd.djvu\")" $failed/testBuildFailure.log
        grep -F "similar name: org.pwmt.zathura.desktop" $failed/testBuildFailure.log
        touch $out
      '';

  overlay =
    let
      overlaid = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };
    in
    pkgs.runCommand "test-overlay"
      {
        list = overlaid.mimetypeDefaults.mkMimeAppsList { apps.pdfViewer = "zathura"; };
      }
      ''
        grep -Fx "[Default Applications]" $list
        grep -Fx "application/pdf=zathura.desktop;" $list
        touch $out
      '';
}
