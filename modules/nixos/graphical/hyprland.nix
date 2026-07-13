{ ... }: {
  flake.nixosModules.graphical = {
    programs = {
      hyprland = {
        enable = true;
        withUWSM = true;
        };
      };
    # hyprland always ships both a "hyprland" and a "hyprland-uwsm" session
    # entry regardless of withUWSM; without this, autoLogin falls back to
    # whichever session is listed first (plain hyprland, not the UWSM one).
    services.displayManager.defaultSession = "hyprland-uwsm";
  };
}
