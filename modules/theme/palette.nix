{ lib, ... }: {
  # Canonical palette of the active theme: named colors only, no app
  # knowledge. A theme module (e.g. tokyonight.nix) fills this and also owns
  # the palette -> per-app view mappings (zathura.colors, nsxiv.colors, ...),
  # including alpha choices. App modules own plugging their view into the
  # actual config format.
  perSystem = { ... }: {
    options.theme.colors = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Named colors as hex strings (#rrggbb / #rrggbbaa)";
    };
  };
}
