{ ... }: {
  # Fonts for the graphical tier, on the home layer: the families in the user
  # profile plus the fontconfig defaults that pick between them. Ported from
  # ~/.config/home-manager, where both halves already lived in Home Manager.
  #
  # This one module reaches every graphical target: the standalone -graphical
  # home configurations import it directly, and the NixOS graphical tier pulls
  # it in through home-manager.sharedModules. DejaVu is deliberately not in
  # the package list -- on NixOS it comes from fonts.enableDefaultPackages,
  # same as on the system this is ported from.
  flake.modules.homeManager.graphical = { pkgs, ... }: {
    home.packages = [
      pkgs.nerd-fonts.dejavu-sans-mono
      pkgs.noto-fonts
      pkgs.noto-fonts-cjk-sans
      # Named by defaultFonts.serif. fonts.enableDefaultPackages only started
      # providing it with the 2026-08 nixpkgs, and never for the standalone
      # -graphical homes, so carry it here.
      pkgs.noto-fonts-cjk-serif
      pkgs.noto-fonts-color-emoji
    ];

    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        # We add the emoji family as a workarround to other font's emojis taking precedence
        # https://github.com/NixOS/nixpkgs/issues/172412
        # The CJK slot used to hold "noto-fonts-cjk", the nixpkgs attr name
        # rather than a fontconfig family, so it never matched and the choice
        # was left to fontconfig. That stopped being harmless in fontconfig
        # 2.18, whose 65-nonlatin.conf made "Noto * CJK KR" the preferred CJK
        # face of every generic and switched Han to Korean glyph variants. JP
        # is the deliberate decision, matching what these machines rendered
        # before that release.
        serif = [ "DejaVu Serif" "Noto Serif CJK JP" "emoji" ];
        sansSerif = [ "DejaVu Sans" "Noto Sans CJK JP" "emoji" ];
        # Symbols 2 before emoji: text-default symbols (nh's U+23F1 stopwatch,
        # arrows, geometric shapes) render monochrome instead of hitting the
        # bitmap emoji font, which kitty draws as a blank cell when the char
        # lacks VS16. VS16-qualified emoji still resolve to Noto Color Emoji.
        # Mono CJK sits after Symbols 2 for the same reason: it also covers the
        # box-drawing and symbol blocks and would otherwise claim them.
        monospace = [ "DejaVu Sans Mono" "Noto Sans Symbols 2" "Noto Sans Mono CJK JP" "emoji" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
