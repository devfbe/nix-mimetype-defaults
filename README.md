# nix-mimetype-defaults

Default applications for NixOS, chosen by role instead of by MIME type.

Windows and macOS let you say "my image viewer is X, my PDF viewer is Y".
On a Linux desktop the same decision is one line per MIME type in
`mimeapps.list` — a dozen lines for an image viewer, seventy for a text
editor. This module carries those lists, so the configuration is back to
one line per role:

```nix
mimetypeDefaults.apps = {
  webBrowser = "firefox";
  pdfViewer = "org.pwmt.zathura";
  imageViewer = "imv";
  textEditor = "code";
  videoPlayer = "mpv";
};
```

An application is named by its desktop file — the file in
`share/applications/` of its package, with or without the `.desktop`
suffix.

## Installation

With flakes:

```nix
{
  inputs.mimetype-defaults = {
    url = "github:devfbe/nix-mimetype-defaults";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, mimetype-defaults, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        mimetype-defaults.nixosModules.default
        { mimetypeDefaults.apps.imageViewer = "imv"; }
      ];
    };
  };
}
```

Without flakes, import the module file from a checkout or tarball:

```nix
let
  mimetypeDefaults = import (fetchTarball "https://github.com/devfbe/nix-mimetype-defaults/archive/main.tar.gz");
in
{
  imports = [ mimetypeDefaults.nixosModules.default ];
}
```

## Classes

| Class | Covers | MIME types |
|---|---|---|
| `webBrowser` | Web pages and http(s) links | 4 |
| `mailClient` | mailto: links and saved e-mails | 2 |
| `calendar` | Calendar files and webcal: links | 3 |
| `fileManager` | Directories | 1 |
| `textEditor` | Plain text, markup, configuration formats and source code | 73 |
| `pdfViewer` | PDF documents | 1 |
| `documentViewer` | Paginated documents other than PDF: PostScript, DjVu, DVI, XPS | 12 |
| `ebookReader` | E-books: EPUB, Mobipocket/Kindle, FictionBook | 5 |
| `comicReader` | Comic book archives (CBZ, CBR) | 2 |
| `imageViewer` | Everyday image formats nearly every viewer opens | 11 |
| `rareImageViewer` | Less common raster formats that need a broad-format tool (GIMP, Gwenview, nomacs) | 22 |
| `rawImageViewer` | Camera raw files (darktable, RawTherapee, ...) | 20 |
| `imageEditor` | Layered project files of image editors: XCF, PSD, OpenRaster, Krita | 5 |
| `videoPlayer` | Video files | 20 |
| `audioPlayer` | Audio files and playlists | 28 |
| `archiveManager` | Archives and compressed files | 24 |
| `wordProcessor` | Text documents: ODT, DOCX, DOC, RTF | 8 |
| `spreadsheet` | Spreadsheets: ODS, XLSX, XLS, CSV | 8 |
| `presentation` | Presentations: ODP, PPTX, PPT | 7 |
| `torrentClient` | Torrent files and magnet: links | 2 |

The exact lists are in [`lib/classes.nix`](lib/classes.nix).

Images are split into four classes on purpose. A default that points at a
program which cannot open the file is worse than no default, and few
viewers open camera raw files or twenty-year-old raster formats. If yours
does, give it several classes:

```nix
mimetypeDefaults.apps = rec {
  imageViewer = "org.kde.gwenview";
  rareImageViewer = imageViewer;
  rawImageViewer = "org.darktable.darktable";
};
```

## Adjusting

```nix
mimetypeDefaults = {
  # Several candidates: the first installed one is used.
  apps.textEditor = [ "code" "nvim" ];

  # Add a type to a built-in class.
  classes.imageViewer.mimeTypes = [ "image/x-farbfeld" ];

  # Take a type out of a built-in class.
  classes.textEditor.excludeMimeTypes = [ "application/json" ];

  # Replace the list of a built-in class.
  classes.pdfViewer.mimeTypes = lib.mkForce [ "application/pdf" "application/x-bzpdf" ];

  # A class of your own.
  classes.cadViewer.mimeTypes = [ "image/vnd.dwg" "image/vnd.dxf" ];
  apps.cadViewer = "librecad";

  # One single type, whatever its class says.
  associations."image/svg+xml" = "org.inkscape.Inkscape";
};
```

If two classes with different applications claim the same MIME type, the
build stops and names the type; settle it with `associations` or
`excludeMimeTypes`.

`config.mimetypeDefaults.resolved` holds the outcome (MIME type → desktop
files) for inspection:

```console
$ nix eval .#nixosConfigurations.myhost.config.mimetypeDefaults.resolved --json | jq
```

## What it does to the system

The module only sets the stock NixOS option `xdg.mime.defaultApplications`,
which writes `/etc/xdg/mimeapps.list`. Consequences:

- **A user's `~/.config/mimeapps.list` wins.** "Set as default" in a
  browser or "Open with → always" in a file manager keeps working and
  overrides the system default for that user. If a default does not take
  effect, look for a stale entry there.
- An entry you set directly in `xdg.mime.defaultApplications` wins over
  this module for that type.
- Setting nothing in `apps` and `associations` changes nothing.

## The desktop file check

A misspelled desktop file is not an error for the desktop; the default is
just ignored. So the system build fails if a default names a desktop file
that no installed package provides, and suggests similar names:

```
mimetype-defaults: no installed package provides 'zathura.desktop' (set for: apps.pdfViewer)
  installed desktop files with a similar name: org.pwmt.zathura.desktop
```

The check searches the system profile and all `users.users.<name>.packages`
(which is where home-manager installs with `useUserPackages = true`). For
applications it cannot see, name the package in
`mimetypeDefaults.check.extraPackages`, or turn the check off with
`mimetypeDefaults.check.enable = false` (Flatpak, per-user profiles).

To find the desktop file of a package:

```console
$ ls $(nix build --no-link --print-out-paths nixpkgs#imv)/share/applications
imv-dir.desktop  imv.desktop
```

## Outside NixOS: lib and overlay

The class data and the resolution are plain functions, exported as the
flake's `lib` and, through `overlays.default`, as `pkgs.mimetypeDefaults`:

```nix
# MIME type -> desktop files
mimetype-defaults.lib.mkAssociations { apps.imageViewer = "imv"; }

# a ready mimeapps.list file, e.g. for home-manager
xdg.configFile."mimeapps.list".source =
  pkgs.mimetypeDefaults.mkMimeAppsList { apps.imageViewer = "imv"; };
```

Both take the same `apps`, `classes` and `associations` arguments as the
module. Unlike the module, `classes` here replaces the built-in set;
extend it with `mimetype-defaults.lib.classes // { ... }`.

## Development

```console
$ nix flake check
```

The checks verify, among other things, that every built-in MIME type is a
canonical shared-mime-info name (an entry under an alias alone never
matches) and that no type sits in two classes.

## License

MIT
