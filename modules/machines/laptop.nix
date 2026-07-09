{ self, inputs, withSystem, ... }: {
  flake.nixosConfigurations.laptop = withSystem "x86_64-linux" ({ self', ... }:
    inputs.nixpkgs.lib.nixosSystem {
      modules = [
        self.nixosModules.base
        {
          networking.hostName = "laptop";
          nixpkgs.hostPlatform = "x86_64-linux";
          environment.systemPackages = [ self'.packages.claude-code ];
        }
      ];
    });
}
