{ lib, ... }: {
  # Canonical palette of the default theme: named colors only, no app
  # knowledge. A theme module (e.g. tokyonight.nix) fills this and also owns
  # the palette -> per-app view mappings (zathura.themes.<name>, nsxiv.colors,
  # ...), including alpha choices. App modules own plugging their view into
  # the actual config format. Non-default themes keep their palette let-bound
  # in their own file and only contribute per-app views under their name.
  perSystem = { ... }: {
    options.theme.colors = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Named colors as hex strings (#rrggbb / #rrggbbaa)";
    };
    options.theme.default = lib.mkOption {
      type = lib.types.str;
      default = "tokyonight";
      description = "Theme used when no runtime choice has been made yet";
    };
  };
}
