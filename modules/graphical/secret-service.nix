{ ... }: {
  # Secret Service (org.freedesktop.secrets) for Electron apps' safeStorage.
  # claude-desktop and chatgpt both pass --password-store=gnome-libsecret on
  # Hyprland (their own perSystem overrides) since Chromium only
  # auto-detects a keyring backend on GNOME/KDE. The PAM hook unlocks the
  # login keyring with the SDDM password so those apps don't prompt for one
  # of their own.
  flake.nixosModules.graphical = { ... }: {
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.sddm.enableGnomeKeyring = true;
  };
}
