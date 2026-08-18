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
      pkgs.noto-fonts-color-emoji
    ];

    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        # We add the emoji family as a workarround to other font's emojis taking precedence
        # https://github.com/NixOS/nixpkgs/issues/172412
        serif = [ "DejaVu Serif" "emoji" ];
        # Ported verbatim: "noto-fonts-cjk" is the nixpkgs attr name, not a
        # fontconfig family (that would be "Noto Sans CJK SC"), so this entry
        # never matches. CJK still renders because fontconfig's generic
        # fallback finds the installed Noto CJK. Fixing it changes rendering,
        # so it stays until a deliberate decision.
        sansSerif = [ "DejaVu Sans" "noto-fonts-cjk" "emoji" ];
        # Symbols 2 before emoji: text-default symbols (nh's U+23F1 stopwatch,
        # arrows, geometric shapes) render monochrome instead of hitting the
        # bitmap emoji font, which kitty draws as a blank cell when the char
        # lacks VS16. VS16-qualified emoji still resolve to Noto Color Emoji.
        monospace = [ "DejaVu Sans Mono" "Noto Sans Symbols 2" "emoji" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
