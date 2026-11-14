<h1 align="center">nix-mimetype-defaults</h1>

<p align="center">
  <b>Default applications for NixOS, chosen by role instead of by MIME type.</b><br>
  “My image viewer is X, my text editor is Y, my PDF viewer is Z.”
</p>

<p align="center">
  <a href="https://github.com/devfbe/nix-mimetype-defaults/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/devfbe/nix-mimetype-defaults/actions/workflows/ci.yml/badge.svg?branch=main"></a>
  <a href="https://github.com/devfbe/nix-mimetype-defaults/releases"><img alt="Latest release" src="https://img.shields.io/github/v/tag/devfbe/nix-mimetype-defaults?label=release&sort=semver"></a>
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-blue"></a>
  <img alt="NixOS module" src="https://img.shields.io/badge/NixOS-module-5277C3?logo=nixos&logoColor=white">
  <img alt="Flakes and non-flakes" src="https://img.shields.io/badge/flakes-%E2%9C%93-informational">
  <img alt="20 built-in classes" src="https://img.shields.io/badge/built--in%20classes-20-success">
</p>

---

Windows and macOS ask one question per role. A Linux desktop wants one
`mimeapps.list` line per MIME type — a dozen for an image viewer, seventy
for a text editor. This module carries those lists for you.

<table>
<tr><th>Without</th><th>With</th></tr>
<tr>
<td>

```nix
xdg.mime.defaultApplications = {
  "image/jpeg" = "imv.desktop";
  "image/png" = "imv.desktop";
  "image/apng" = "imv.desktop";
  "image/gif" = "imv.desktop";
  "image/webp" = "imv.desktop";
  "image/avif" = "imv.desktop";
  "image/heif" = "imv.desktop";
  "image/jxl" = "imv.desktop";
  "image/bmp" = "imv.desktop";
  "image/tiff" = "imv.desktop";
  "image/svg+xml" = "imv.desktop";
  "application/pdf" = "org.pwmt.zathura.desktop";
  # ... and 73 more for the text editor
};
```

</td>
<td>

```nix
mimetypeDefaults.apps = {
  imageViewer = "imv";
  pdfViewer = "org.pwmt.zathura";
  textEditor = "code";
};
```

</td>
</tr>
</table>

## Contents

- [Quick start](#quick-start)
- [Classes](#classes)
- [Adjusting](#adjusting)
- [Options](#options)
- [How a default is decided](#how-a-default-is-decided)
- [The desktop file check](#the-desktop-file-check)
- [Troubleshooting](#troubleshooting)
- [Outside NixOS: lib and overlay](#outside-nixos-lib-and-overlay)
- [Development](#development)

## Quick start

Add the flake input and the module, then name your applications:

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
        {
          mimetypeDefaults.apps = {
            webBrowser = "firefox";
            pdfViewer = "org.pwmt.zathura";
            imageViewer = "imv";
            textEditor = "code";
            videoPlayer = "mpv";
          };
        }
      ];
    };
  };
}
```

`main` is kept working; to stay on a released version instead, pin a tag:
`url = "github:devfbe/nix-mimetype-defaults/v0.1.0";`
([releases](https://github.com/devfbe/nix-mimetype-defaults/releases)).

An application is named by its **desktop file**: the file in
`share/applications/` of its package, with or without the `.desktop`
suffix. To find it:

```console
$ ls $(nix build --no-link --print-out-paths nixpkgs#imv)/share/applications
imv-dir.desktop  imv.desktop
```

<details>
<summary><b>Without flakes</b></summary>

```nix
let
  mimetypeDefaults = import (fetchTarball "https://github.com/devfbe/nix-mimetype-defaults/archive/main.tar.gz");
in
{
  imports = [ mimetypeDefaults.nixosModules.default ];
  mimetypeDefaults.apps.imageViewer = "imv";
}
```

</details>

## Classes

Twenty classes are built in. Set the ones you care about; the rest stay
untouched.

| | Class | Covers | Types | Desktop files, for example |
|---|---|---|--:|---|
| 🌐 | `webBrowser` | Web pages and http(s) links | 4 | `firefox`, `google-chrome`, `chromium-browser` |
| ✉️ | `mailClient` | mailto: links and saved e-mails | 2 | `thunderbird` |
| 📅 | `calendar` | Calendar files and webcal: links | 3 | `org.gnome.Calendar`, `org.kde.korganizer` |
| 📁 | `fileManager` | Directories | 1 | `pcmanfm-qt`, `org.kde.dolphin`, `org.gnome.Nautilus` |
| 📝 | `textEditor` | Plain text, markup, configuration formats and source code | 73 | `code`, `nvim`, `org.kde.kate` |
| 📕 | `pdfViewer` | PDF documents | 1 | `org.pwmt.zathura`, `org.gnome.Evince`, `org.kde.okular` |
| 📄 | `documentViewer` | Paginated documents other than PDF: PostScript, DjVu, DVI, XPS | 12 | `org.gnome.Evince`, `org.kde.okular` |
| 📚 | `ebookReader` | E-books: EPUB, Mobipocket/Kindle, FictionBook | 5 | `com.github.johnfactotum.Foliate` |
| 💬 | `comicReader` | Comic book archives (CBZ, CBR) | 2 | `mcomix` |
| 🖼️ | `imageViewer` | Everyday image formats nearly every viewer opens | 11 | `imv`, `org.gnome.Loupe`, `org.kde.gwenview` |
| 🗃️ | `rareImageViewer` | Less common raster formats that need a broad-format tool | 22 | `gimp`, `org.kde.gwenview` |
| 📷 | `rawImageViewer` | Camera raw files | 20 | `org.darktable.darktable` |
| 🎨 | `imageEditor` | Layered project files: XCF, PSD, OpenRaster, Krita | 5 | `gimp`, `org.kde.krita` |
| 🎬 | `videoPlayer` | Video files | 20 | `mpv`, `vlc` |
| 🎵 | `audioPlayer` | Audio files and playlists | 28 | `mpv`, `audacious`, `org.gnome.Rhythmbox3` |
| 📦 | `archiveManager` | Archives and compressed files | 24 | `org.gnome.FileRoller`, `org.kde.ark` |
| 📃 | `wordProcessor` | Text documents: ODT, DOCX, DOC, RTF | 8 | `writer` (LibreOffice) |
| 📊 | `spreadsheet` | Spreadsheets: ODS, XLSX, XLS, CSV | 8 | `calc` (LibreOffice) |
| 📽️ | `presentation` | Presentations: ODP, PPTX, PPT | 7 | `impress` (LibreOffice) |
| 🧲 | `torrentClient` | Torrent files and magnet: links | 2 | `org.qbittorrent.qBittorrent`, `transmission-gtk` |

The exact type lists are in [`lib/classes.nix`](lib/classes.nix). The
desktop file names are examples and can differ between package versions;
the [check](#the-desktop-file-check) tells you when one is wrong.

> [!NOTE]
> **Why four image classes?** A default that points at a program which
> cannot open the file is worse than no default, and few viewers open
> camera raw files or twenty-year-old raster formats. If yours does, give
> it several classes:
>
> ```nix
> mimetypeDefaults.apps = rec {
>   imageViewer = "org.kde.gwenview";
>   rareImageViewer = imageViewer;
>   rawImageViewer = "org.darktable.darktable";
> };
> ```

## Adjusting

Everything the built-in classes decide can be extended or overridden:

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

## Options

| Option | Type | What it does |
|---|---|---|
| `mimetypeDefaults.apps.<class>` | desktop file, list of them, or `null` | The application for a class. A list is an order of preference. |
| `mimetypeDefaults.classes.<class>.mimeTypes` | list of MIME types | The types of a class. Definitions add up; `lib.mkForce` replaces. |
| `mimetypeDefaults.classes.<class>.excludeMimeTypes` | list of MIME types | Types to drop from a class. |
| `mimetypeDefaults.associations.<type>` | desktop file or list of them | The default for one type; wins over every class. |
| `mimetypeDefaults.check.enable` | bool, default `true` | Fail the build on desktop files nobody provides. |
| `mimetypeDefaults.check.extraPackages` | list of packages | More places for the check to look. |
| `mimetypeDefaults.resolved` | read-only | The outcome: MIME type → desktop files. |

## How a default is decided

The module only sets the stock NixOS option
`xdg.mime.defaultApplications`, which writes `/etc/xdg/mimeapps.list`.
For any one MIME type, the first of these that says something wins:

1. **The user's `~/.config/mimeapps.list`** — “Set as default” in a
   browser or “Open with → always” in a file manager keeps working and
   overrides the system default for that user.
2. **`xdg.mime.defaultApplications`** set directly in your configuration.
3. **`mimetypeDefaults.associations`** for that type.
4. **`mimetypeDefaults.apps`** through the class the type belongs to.
5. Nothing set: the desktop picks any installed program that claims the
   type — the lottery this module exists to end.

Setting nothing in `apps` and `associations` changes nothing on your
system. If two classes with different applications claim the same type,
the build stops and names it; settle it with `associations` or
`excludeMimeTypes`.

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

## Troubleshooting

**A default does not take effect.** Look for an entry for that type in
`~/.config/mimeapps.list`; it wins over the system default. Remove the
line to fall back to your configuration.

**Which type is this file, and what opens it?**

```console
$ xdg-mime query filetype photo.heic
image/heif
$ xdg-mime query default image/heif
imv.desktop
```

**What did the module decide?**

```console
$ nix eval .#nixosConfigurations.myhost.config.mimetypeDefaults.resolved --json | jq
```

**A type I added is ignored.** Use the canonical name that
`xdg-mime query filetype` prints. Desktops look up the canonical type, so
an entry under an alias (`image/x-psd` instead of
`image/vnd.adobe.photoshop`) never matches.

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
canonical shared-mime-info name, that no type sits in two classes, and
that this README lists every class.

CI runs the checks on every push and pull request, against the locked
nixpkgs and against current `nixos-unstable`. Pushing a tag `v*` creates
a GitHub release after the checks passed.

Missing a format or a class? Issues and pull requests are welcome.

## License

[MIT](LICENSE)
