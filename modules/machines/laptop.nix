{ self, inputs, ... }: {
  flake.nixosConfigurations.laptop = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.base
      {
        networking.hostName = "laptop";
        nixpkgs.hostPlatform = "x86_64-linux";
      }
    ];
  };
}
