# Built-in application classes: a role name ("my image viewer") mapped to
# the MIME types that role is responsible for.
#
# Rules for this file (enforced by the flake checks):
#   - Names are the canonical shared-mime-info names. A desktop looks up
#     the *canonical* type in mimeapps.list, so an entry under an alias
#     alone never matches. Where the canonical name changed between
#     shared-mime-info releases, both names are listed so the class works
#     on either side of the rename.
#   - No MIME type appears in two classes.
#   - A class only lists formats that typical applications of that role
#     can really open: pointing a type at a program that fails on it is
#     worse than leaving the type alone.
{
  webBrowser = {
    description = "Web pages and http(s) links";
    mimeTypes = [
      "text/html"
      "application/xhtml+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
  };

  mailClient = {
    description = "mailto: links and saved e-mails";
    mimeTypes = [
      "x-scheme-handler/mailto"
      "message/rfc822"
    ];
  };

  calendar = {
    description = "Calendar files and webcal: links";
    mimeTypes = [
      "text/calendar"
      "x-scheme-handler/webcal"
      "x-scheme-handler/webcals"
    ];
  };

  fileManager = {
    description = "Directories";
    mimeTypes = [ "inode/directory" ];
  };

  textEditor = {
    description = "Plain text, markup, configuration formats and source code";
    mimeTypes = [
      # Prose and markup
      "text/plain"
      "text/markdown"
      "text/org"
      "text/x-rst"
      "text/x-tex"
      "text/x-bibtex"
      "text/x-typst"
      "text/vnd.typst" # canonical name in newer shared-mime-info
      "text/x-readme"
      "text/x-log"
      "text/x-patch"
      "text/x-changelog"
      "text/x-authors"
      "text/x-copying"
      "text/x-credits"
      "text/x-install"
      # Data and configuration
      "application/json"
      "application/json5"
      "application/xml"
      "application/xslt+xml"
      "application/yaml"
      "application/x-yaml" # alias, canonical before shared-mime-info 2.3
      "application/toml"
      "application/sql"
      "text/x-systemd-unit"
      "text/vnd.graphviz"
      # Web
      "text/css"
      "text/x-scss"
      "text/x-sass"
      "text/javascript"
      "application/javascript" # alias, canonical before shared-mime-info 2.4
      # Scripts and build files
      "application/x-shellscript"
      "text/x-shellscript" # canonical name in newer shared-mime-info
      "application/x-perl"
      "application/x-php"
      "application/x-ruby"
      "text/x-python"
      "text/x-python3"
      "text/x-lua"
      "text/tcl"
      "text/x-makefile"
      "text/x-cmake"
      "text/x-meson"
      "text/x-gradle"
      # Compiled and other languages
      "text/x-csrc"
      "text/x-chdr"
      "text/x-c++src"
      "text/x-c++hdr"
      "text/x-objcsrc"
      "text/x-csharp"
      "text/x-java"
      "text/x-kotlin"
      "text/x-scala"
      "text/x-groovy"
      "text/rust"
      "text/x-go"
      "text/x-haskell"
      "text/x-ocaml"
      "text/x-erlang"
      "text/x-elixir"
      "text/x-pascal"
      "text/x-fortran"
      "text/x-adasrc"
      "text/x-vala"
      "text/x-nim"
      "text/x-crystal"
      "text/julia"
      "text/x-dsrc"
      "text/x-common-lisp"
      "text/x-emacs-lisp"
      "text/x-scheme"
      "text/x-qml"
      "text/x-verilog"
      "text/x-vhdl"
      "text/x-devicetree-source"
    ];
  };

  pdfViewer = {
    description = "PDF documents";
    mimeTypes = [ "application/pdf" ];
  };

  documentViewer = {
    description = "Paginated documents other than PDF: PostScript, DjVu, DVI, XPS";
    mimeTypes = [
      "application/postscript"
      "image/x-eps"
      "application/x-dvi"
      "image/vnd.djvu"
      "image/vnd.djvu+multipage"
      "application/oxps"
      "application/vnd.ms-xpsdocument"
      "application/x-gzpdf"
      "application/x-bzpdf"
      "application/x-xzpdf"
      "application/x-gzpostscript"
      "application/x-bzpostscript"
    ];
  };

  ebookReader = {
    description = "E-books: EPUB, Mobipocket/Kindle, FictionBook";
    mimeTypes = [
      "application/epub+zip"
      "application/x-mobipocket-ebook"
      "application/vnd.amazon.mobi8-ebook"
      "application/x-fictionbook+xml"
      "application/x-zip-compressed-fb2"
    ];
  };

  comicReader = {
    description = "Comic book archives (CBZ, CBR)";
    mimeTypes = [
      "application/vnd.comicbook+zip"
      "application/vnd.comicbook-rar"
    ];
  };

  imageViewer = {
    description = "Everyday image formats nearly every viewer opens";
    mimeTypes = [
      "image/jpeg"
      "image/png"
      "image/apng"
      "image/gif"
      "image/webp"
      "image/avif"
      "image/heif"
      "image/jxl"
      "image/bmp"
      "image/tiff"
      "image/svg+xml"
    ];
  };

  rareImageViewer = {
    description = "Less common raster formats that need a broad-format tool (GIMP, Gwenview, nomacs)";
    mimeTypes = [
      "image/jp2"
      "image/x-jp2-codestream"
      "image/qoi"
      "image/vnd.microsoft.icon"
      "image/x-icns"
      "image/x-tga"
      "image/vnd.zbrush.pcx"
      "image/x-dds"
      "image/vnd.ms-dds" # canonical name in newer shared-mime-info
      "image/x-exr"
      "image/x-sgi"
      "image/x-sun-raster"
      "image/x-ilbm"
      "image/x-portable-anymap"
      "image/x-portable-bitmap"
      "image/x-portable-graymap"
      "image/x-portable-pixmap"
      "image/x-xbitmap"
      "image/x-xpixmap"
      "image/x-xwindowdump"
      "image/vnd.wap.wbmp"
      "image/g3fax"
      "image/wmf"
    ];
  };

  rawImageViewer = {
    description = "Camera raw files (darktable, RawTherapee, ...)";
    mimeTypes = [
      "image/x-dcraw"
      "image/x-adobe-dng"
      "image/x-canon-cr2"
      "image/x-canon-cr3"
      "image/x-canon-crw"
      "image/x-fuji-raf"
      "image/x-kodak-dcr"
      "image/x-kodak-k25"
      "image/x-kodak-kdc"
      "image/x-minolta-mrw"
      "image/x-nikon-nef"
      "image/x-nikon-nrw"
      "image/x-olympus-orf"
      "image/x-panasonic-rw"
      "image/x-panasonic-rw2"
      "image/x-pentax-pef"
      "image/x-sigma-x3f"
      "image/x-sony-arw"
      "image/x-sony-sr2"
      "image/x-sony-srf"
    ];
  };

  imageEditor = {
    description = "Layered project files of image editors: XCF, PSD, OpenRaster, Krita";
    mimeTypes = [
      "image/x-xcf"
      "image/x-compressed-xcf"
      "image/vnd.adobe.photoshop"
      "image/openraster"
      "application/x-krita"
    ];
  };

  videoPlayer = {
    description = "Video files";
    mimeTypes = [
      "video/mp4"
      "video/x-matroska"
      "video/matroska" # canonical name in newer shared-mime-info
      "video/x-matroska-3d"
      "video/matroska-3d" # canonical name in newer shared-mime-info
      "video/webm"
      "video/quicktime"
      "video/vnd.avi"
      "video/x-msvideo" # alias, canonical before shared-mime-info 2.3
      "video/mpeg"
      "video/mp2t"
      "video/ogg"
      "video/x-theora+ogg"
      "video/x-ogm+ogg"
      "video/x-flv"
      "video/3gpp"
      "video/3gpp2"
      "video/x-ms-wmv"
      "video/dv"
      "video/vnd.rn-realvideo"
      "application/vnd.rn-realmedia"
      "application/mxf"
    ];
  };

  audioPlayer = {
    description = "Audio files and playlists";
    mimeTypes = [
      "audio/mpeg"
      "audio/mp4"
      "audio/x-m4b"
      "audio/aac"
      "audio/flac"
      "audio/x-flac+ogg"
      "audio/ogg"
      "audio/x-vorbis+ogg"
      "audio/x-opus+ogg"
      "audio/x-speex+ogg"
      "audio/vnd.wave"
      "audio/x-wav" # alias, canonical before shared-mime-info 2.3
      "audio/x-aiff"
      "audio/x-ms-wma"
      "audio/x-matroska"
      "audio/matroska" # canonical name in newer shared-mime-info
      "audio/webm"
      "audio/x-ape"
      "audio/x-wavpack"
      "audio/x-musepack"
      "audio/x-tta"
      "audio/ac3"
      "audio/vnd.dts"
      "audio/mp2"
      "audio/AMR"
      "audio/midi"
      # Playlists
      "audio/x-mpegurl"
      "audio/x-scpls"
      "application/xspf+xml"
    ];
  };

  archiveManager = {
    description = "Archives and compressed files";
    mimeTypes = [
      "application/zip"
      "application/x-7z-compressed"
      "application/vnd.rar"
      "application/x-tar"
      "application/x-compressed-tar"
      "application/x-bzip2-compressed-tar"
      "application/x-bzip-compressed-tar" # alias, canonical before shared-mime-info 2.3
      "application/x-xz-compressed-tar"
      "application/x-zstd-compressed-tar"
      "application/x-lzma-compressed-tar"
      "application/x-lz4-compressed-tar"
      "application/x-lzip-compressed-tar"
      "application/x-tarz"
      "application/gzip"
      "application/x-bzip2"
      "application/x-bzip" # alias, canonical before shared-mime-info 2.3
      "application/x-xz"
      "application/zstd"
      "application/x-lzma"
      "application/x-lz4"
      "application/x-lzip"
      "application/x-compress"
      "application/x-cpio"
      "application/vnd.ms-cab-compressed"
    ];
  };

  wordProcessor = {
    description = "Text documents: ODT, DOCX, DOC, RTF";
    mimeTypes = [
      "application/vnd.oasis.opendocument.text"
      "application/vnd.oasis.opendocument.text-template"
      "application/vnd.oasis.opendocument.text-flat-xml"
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      "application/vnd.openxmlformats-officedocument.wordprocessingml.template"
      "application/msword"
      "application/msword-template"
      "application/rtf"
    ];
  };

  spreadsheet = {
    description = "Spreadsheets: ODS, XLSX, XLS, CSV";
    mimeTypes = [
      "application/vnd.oasis.opendocument.spreadsheet"
      "application/vnd.oasis.opendocument.spreadsheet-template"
      "application/vnd.oasis.opendocument.spreadsheet-flat-xml"
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      "application/vnd.openxmlformats-officedocument.spreadsheetml.template"
      "application/vnd.ms-excel"
      "text/csv"
      "text/tab-separated-values"
    ];
  };

  presentation = {
    description = "Presentations: ODP, PPTX, PPT";
    mimeTypes = [
      "application/vnd.oasis.opendocument.presentation"
      "application/vnd.oasis.opendocument.presentation-template"
      "application/vnd.oasis.opendocument.presentation-flat-xml"
      "application/vnd.openxmlformats-officedocument.presentationml.presentation"
      "application/vnd.openxmlformats-officedocument.presentationml.slideshow"
      "application/vnd.openxmlformats-officedocument.presentationml.template"
      "application/vnd.ms-powerpoint"
    ];
  };

  torrentClient = {
    description = "Torrent files and magnet: links";
    mimeTypes = [
      "application/x-bittorrent"
      "x-scheme-handler/magnet"
    ];
  };
}
