{ inputs, ... }: {
  # User-session half of the graphical tier. NixOS owns the compositor and
  # display manager; this owns the per-user programs that only make sense once
  # Hyprland has made its Wayland and IPC environment available.
  flake.modules.homeManager.graphical = { pkgs, ... }: {
    imports = [
      inputs.gtk-status-bar.homeModules.default
      inputs.status-overlay.homeModules.default
    ];

    # Both upstream modules define, but intentionally do not enable, a user
    # service. That keeps them out of a non-graphical login and lets Hyprland
    # start them only after its instance signature is known.
    programs.gtk-status-bar.enable = true;
    programs.status-overlay.enable = true;

    home.packages = [ pkgs.foot ];

    wayland.windowManager.hyprland = {
      enable = true;
      configType = "hyprlang";
      # NixOS starts the UWSM session. A second Home Manager-managed unit would
      # compete with that owner for the compositor lifecycle.
      systemd.enable = false;
      settings = {
        "$mod" = "SUPER";
        bind = [ "$mod, RETURN, exec, ${pkgs.foot}/bin/foot" ];
        exec-once = [
          # UWSM provides the Wayland variables, while Hyprland creates this
          # signature only after startup. The services need both for IPC.
          "systemctl --user import-environment HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
          "systemctl --user start gtk-status-bar.service"
          "systemctl --user start status-overlay.service"
        ];
      };
    };
  };
}
