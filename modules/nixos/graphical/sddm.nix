{ ... }: {
  # Part of the graphical tier (composed in modules/machines/hosts.nix). SDDM
  # with a wayland greeter, plus the login keyring: the PAM hook unlocks it at
  # login and the gnome-keyring daemon has to actually be running for that
  # unlock to mean anything.
  flake.nixosModules.graphical = {
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;

    security.pam.services.sddm.enableGnomeKeyring = true;
    services.gnome.gnome-keyring.enable = true;
  };
}
