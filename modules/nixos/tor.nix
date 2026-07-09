{ ... }: {
  flake.nixosModules.base = { pkgs, ... }: {
    services.tor = {
      enable = true;
      torsocks.enable = true;
      client.enable = true;
    };
  };
}
