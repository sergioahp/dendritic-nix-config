{ lib, ... }: {
  perSystem = { ... }:
    let
      colorLib = import ./_color-lib.nix { inherit lib; };
      inherit (colorLib) withAlpha;

      # Light pastel palette: near-white surfaces, soft desaturated accents.
      # Appearance-based names only; roles are assigned in the views below.
      c = {
        snow = "#f7f7fb";
        alabaster = "#eceaf4";
        wisteria = "#b3a5dd";
        peach = "#f0b58c";
        powder-blue = "#a9c3e6";
        cornflower = "#6f8fd6";
        slate-mauve = "#7a7f9a";
        graphite = "#4d5265";
        rose = "#c76a7a";
        apricot = "#cf9550";
      };
    in
    {
      # Non-default theme: palette stays local, only per-app views are
      # exported. Key set must match the other zathura themes (the runtime
      # switch replays the full set; enforced in zathura.nix).
      zathura.themes.pastel =
        let
          # light transparency only: the page should read as paper
          bg-95 = withAlpha c.snow 0.95;
          highlight-50 = withAlpha c.wisteria 0.5;
          highlight-active-60 = withAlpha c.peach 0.6;
        in
        {
          default-bg = bg-95;
          statusbar-bg = c.alabaster;
          statusbar-fg = c.cornflower;
          # bug: no alpha support on the inputbar-bg
          inputbar-bg = bg-95;
          inputbar-fg = c.slate-mauve;
          notification-error-bg = bg-95;
          notification-warning-bg = bg-95;
          notification-bg = bg-95;
          notification-error-fg = c.rose;
          notification-warning-fg = c.apricot;
          notification-fg = c.slate-mauve;
          highlight-active-color = highlight-active-60;
          highlight-color = highlight-50;
          completion-bg = c.alabaster;
          completion-fg = c.graphite;
          completion-highlight-bg = highlight-50;
          completion-highlight-fg = c.cornflower;
          recolor-lightcolor = "#00000000";
          recolor-darkcolor = c.graphite;
        };
    };
}
