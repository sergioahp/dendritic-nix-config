{ ... }: {
  perSystem = { config, pkgs, self', inputs', ... }:
    let
      claude-desktop-pkg = inputs'.llm-agents.packages.claude-desktop;
    in
      {
      options = {};
      config.packages = {
        claude-desktop = claude-desktop-pkg.override {
          # Chromium only auto-detects a keyring backend on GNOME and KDE; on
          # Hyprland it doesn't, and claude-desktop then warns sign-in won't
          # be saved. HYPRLAND_INSTANCE_SIGNATURE is only set inside a
          # Hyprland session, so this stays stock (no extra arg) everywhere
          # else - the same trick upstream uses for its own
          # NIXOS_OZONE_WL-gated flags.

          # Keep monitoring upstream in case they come up with their own
          # solution for the password store on Hyprland.

          # Requires gnome-keyring to be installed.
          commandLineArgs = "\${HYPRLAND_INSTANCE_SIGNATURE:+--password-store=gnome-libsecret}";
        };
      };
    };

  # GUI app, so it only lands on the graphical tier (desktop-graphical,
  # laptop-graphical, and their build-vm variant) - never the headless one.
  flake.nixosModules.graphical = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.claude-desktop ];
  };
}
