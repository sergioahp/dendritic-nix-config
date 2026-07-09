{ self, inputs, ... }: {
  flake.nixosConfigurations.desktop = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.base
      {
        networking.hostName = "desktop";
        nixpkgs.hostPlatform = "x86_64-linux";
      }
    ];
  };
}
