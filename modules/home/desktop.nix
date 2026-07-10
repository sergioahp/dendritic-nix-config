{ self, inputs, withSystem, ... }: {
  flake.homeConfigurations.desktop = withSystem "x86_64-linux" ({ system, ... }:
    inputs.home-manager.lib.homeManagerConfiguration {
      # User packages ride nixpkgs-hm (the faster-moving nixpkgs), not the
      # system's nixos-unstable that withSystem's pkgs would hand us.
      pkgs = inputs.nixpkgs-hm.legacyPackages.${system};
      modules = [ self.modules.homeManager.base ];
      extraSpecialArgs = { inherit inputs; };
    });
}
