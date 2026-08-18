{ ... }: {
  # Audio for the graphical tier: pipewire, with the pulse and alsa
  # compatibility layers so anything that only speaks those still plays.
  #
  # Strictly speaking this tier already had sound: programs.hyprland.enable
  # pulls in nixpkgs' wayland-session.nix, which sets
  # services.graphical-desktop.enable, which turns pipewire (+ pulse + alsa) on
  # with mkDefault. Written out anyway -- audio on a desktop is a decision, not
  # something to inherit two modules deep from a compositor and only find out
  # about when a nixpkgs default moves.
  flake.nixosModules.graphical = {
    services.pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
    };
  };
}
