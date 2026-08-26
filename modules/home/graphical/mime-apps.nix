{ ... }: {
  # Default applications for the graphical tier: the xdg.mimeApps table ported
  # verbatim from ~/.config/home-manager, plus the three programs whose desktop
  # files it names. Home Manager writes ~/.config/mimeapps.list the usual way;
  # there is no system-level associations file.
  #
  # The packages come from the overlaid pkgs (self.overlays.default, applied
  # where hosts.nix instantiates nixpkgs-hm), so nsxiv and zathura are the
  # repo's wrapped theme-aware builds. One generation then carries the binary,
  # the desktop file and the association, and the three can never skew.
  #
  # Reaches every graphical target like the fonts module does: standalone
  # -graphical home configurations import it directly, the NixOS graphical tier
  # pulls it in through home-manager.sharedModules.
  flake.modules.homeManager.graphical = { pkgs, ... }: {
    home.packages = [ pkgs.nsxiv pkgs.zathura pkgs.firefox ];

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        # images
        "image/bmp" = [ "nsxiv.desktop" ];
        "image/gif" = [ "nsxiv.desktop" ];
        "image/jpeg" = [ "nsxiv.desktop" ];
        "image/png" = [ "nsxiv.desktop" ];
        "image/tiff" = [ "nsxiv.desktop" ];
        "image/x-bmp" = [ "nsxiv.desktop" ];
        "image/x-portable-bitmap" = [ "nsxiv.desktop" ];
        "image/x-portable-graymap" = [ "nsxiv.desktop" ];
        "image/x-tga" = [ "nsxiv.desktop" ];
        "image/x-xpixmap" = [ "nsxiv.desktop" ];
        "image/webp" = [ "nsxiv.desktop" ];
        "image/heic" = [ "nsxiv.desktop" ];
        "image/svg+xml" = [ "nsxiv.desktop" ];
        "application/postscript" = [ "nsxiv.desktop" ];
        "image/jp2" = [ "nsxiv.desktop" ];
        "image/jxl" = [ "nsxiv.desktop" ];
        "image/avif" = [ "nsxiv.desktop" ];
        "image/heif" = [ "nsxiv.desktop" ];
        # documents
        "image/vnd.djvu" = [ "org.pwmt.zathura.desktop" ];
        "image/x-djvu" = [ "org.pwmt.zathura.desktop" ];
        "application/pdf" = [ "org.pwmt.zathura.desktop" ];
        # firefox
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
        "x-scheme-handler/chrome" = [ "firefox.desktop" ];
        "text/html" = [ "firefox.desktop" ];
      };
    };
  };
}
