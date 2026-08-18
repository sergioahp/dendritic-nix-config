{ ... }: {
  # The compositor session, shared by every graphical host.
  #
  # Deliberately no `package` here: msi and laptop run whatever hyprland the
  # pinned nixpkgs ships, and that is the normal case. nixd is the exception --
  # a GTX 760 (Kepler) on nouveau, where newer hyprland releases froze the
  # session at startup and the fix that actually worked was rolling back to
  # v0.49.0, not switching drivers. That is a fact about one GPU, so when nixd's
  # graphical half migrates it overrides programs.hyprland.package (and
  # portalPackage, which follows it) on its own machine module. If that
  # override needs a flake input, the input goes in unpinned and flake.lock
  # holds the revision -- no rev or tag written into flake.nix, which is how
  # the old ~/nixos config carried its pin and how it ended up being a
  # revision nothing tracked.
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
