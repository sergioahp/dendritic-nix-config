{ ... }: {
  # Part of the graphical tier (composed in modules/machines/hosts.nix). SDDM
  # with a wayland greeter.
  #
  # The login keyring used to live here, next to the PAM hook that unlocks it.
  # It moved to modules/graphical/claude-desktop.nix, the one app that needs a
  # Secret Service: both halves (daemon + hook) sit with their consumer, so
  # whoever drops claude-desktop takes the keyring with it instead of leaving
  # an unexplained daemon behind.
  flake.nixosModules.graphical = {
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;
  };
}
