{ lib, ... }: {
  perSystem = { ... }:
    let
      colorLib = import ./_color-lib.nix { inherit lib; };
      inherit (colorLib) withAlpha;

      # Canonical palette: names describe the color's appearance only, never
      # its eventual use; roles/uses are assigned in the per-app views below.
      c = {
        gunmetal = "#282c3c";
        charcoal = "#1f2026";
        midnight = "#1e2030";
        periwinkle-light = "#c8d3f5";
        navy = "#2d3f76";
        coral = "#ff966c";
        ink = "#16161e";
        void = "#0C0E14";
        black = "#15161e";
        white = "#ffffff";
        slate = "#292e42";
        electric-blue = "#82aaff";
        electric-blue2 = "#828bb8";
        blue = "#7aa2f7";
        blue0 = "#3d59a1";
        blue1 = "#2ac3de";
        blue2 = "#0db9d7";
        blue5 = "#89ddff";
        blue6 = "#b4f9f8";
        blue7 = "#394b70";
        bright-blue = "#8db0ff";
        grey-blue = "#565f89";
        cyan = "#7dcfff";
        cyan2 = "#65bcff";
        bright-cyan = "#a4daff";
        dark3 = "#545c7e";
        dark5 = "#737aa2";
        periwinkle = "#c0caf5";
        periwinkle-grey = "#a9b1d6";
        steel-blue = "#3b4261";
        green = "#9ece6a";
        bright-green = "#9fe044";
        green1 = "#73daca";
        green2 = "#41a6b5";
        magenta = "#bb9af7";
        magenta2 = "#ff007c";
        bright-magenta = "#c7a9ff";
        orange = "#ff9e64";
        purple = "#9d7cd8";
        red = "#f7768e";
        bright-red = "#ff899d";
        red1 = "#db4b4b";
        red2 = "#c53b53";
        teal = "#1abc9c";
        storm-grey = "#414868";
        yellow = "#e0af68";
        bright-yellow = "#faba4a";
        yellow2 = "#ffc777";
        # Additional UI colors
        pale-red = "#dca6af";
        ice-blue = "#88C0D0";
        pale-gold = "#EBCB8B";
        # Claude's signature colors
        clay = "#b48a7c";
        terracotta = "#D97757";
        # Lock screen colors
        steel-grey = "#5b6078";
        abyss = "#181926";
        silver = "#c8c8c8";
      };
    in
    {
      # tokyonight is the default theme, so it also exports the canonical
      # palette for single-theme consumers (nsxiv, future dunst, ...)
      theme.colors = c;

      # This theme's view of each app: pick palette entries for the app's
      # color slots and assign alphas here; the app module owns formatting
      # and placement. All zathura themes must define the same key set (the
      # runtime switch replays the full set; enforced in zathura.nix).
      zathura.themes.tokyonight =
        let
          bg-80 = withAlpha c.gunmetal 0.8;
          highlight-60 = withAlpha c.navy 0.6;
          highlight-active-60 = withAlpha c.coral 0.6;
        in
        {
          default-bg = bg-80;
          statusbar-bg = c.midnight;
          statusbar-fg = c.electric-blue;
          # bug: no alpha support on the inputbar-bg
          inputbar-bg = bg-80;
          inputbar-fg = c.electric-blue2;
          notification-error-bg = bg-80;
          notification-warning-bg = bg-80;
          notification-bg = bg-80;
          notification-error-fg = c.red2;
          notification-warning-fg = c.yellow2;
          notification-fg = c.electric-blue2;
          highlight-active-color = highlight-active-60;
          highlight-color = highlight-60;
          completion-bg = c.midnight;
          completion-fg = c.periwinkle-light;
          completion-highlight-bg = highlight-60;
          completion-highlight-fg = c.cyan2;
          recolor-lightcolor = "#00000000";
          recolor-darkcolor = c.white;
        };

      nsxiv.colors = {
        window-bg = c.gunmetal;
        window-fg = c.periwinkle;
        bar-bg = c.midnight;
        bar-fg = c.electric-blue;
      };
    };
}
