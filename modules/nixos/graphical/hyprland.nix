{ ... }: {
  flake.nixosModules.graphical = {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

    # hyprland always ships both a "hyprland" and a "hyprland-uwsm" session
    # entry regardless of withUWSM; without this, autoLogin falls back to
    # whichever session is listed first (plain hyprland, not the UWSM one).
    services.displayManager.defaultSession = "hyprland-uwsm";

    # xdg-desktop-portal-hyprland does not implement the Settings interface, so
    # org.freedesktop.appearance color-scheme is unreadable unless Settings is
    # routed to the gtk backend explicitly (the default=hyprland;gtk fallback
    # from the hyprland portal's own config does not expose it). hyprland stays
    # the default for screenshot/screencast.
    #
    # Only the routing is here: the portal itself, the hyprland backend and the
    # gtk backend all come from programs.hyprland.enable via nixpkgs'
    # wayland-session.nix, which is newer than the ~/nixos config that still
    # lists xdg-desktop-portal-gtk by hand.
    xdg.portal.config.common = {
      default = [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
    };

    # With no X server running this contributes exactly one thing: libinput's
    # udev rules (the xf86-input-libinput half of the module is gated on
    # services.xserver.enable). Cheap, and it is what the touchpad quirks ride
    # in on.
    services.libinput.enable = true;
  };
}
