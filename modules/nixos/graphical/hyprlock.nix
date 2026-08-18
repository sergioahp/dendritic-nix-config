{ ... }: {
  # Screen lock for the hyprland session.
  #
  # The nixpkgs module already declares security.pam.services.hyprlock (without
  # it hyprlock falls back to su and the unlock silently fails), so unlike the
  # ~/nixos config this does not have to restate the PAM service.
  #
  # It also switches on services.hypridle, whose user unit wants a
  # ~/.config/hypr/hypridle.conf. That file is the home layer's job; until it
  # exists the idle daemon is the only thing that notices.
  flake.nixosModules.graphical = {
    programs.hyprlock.enable = true;
  };
}
