{ ... }: {
  flake.nixosModules.base = {
    system.stateVersion = "25.11";
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    time.timeZone = "America/Mexico_City";
    i18n.defaultLocale = "en_US.UTF-8";
  };
}
