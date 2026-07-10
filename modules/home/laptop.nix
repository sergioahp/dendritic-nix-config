{ self, inputs, withSystem, ... }: {
  # Identical to desktop for now; diverges later on screen, mouse, chrome gpu
  # accel and other host-specific bits, which will import a laptop-only module
  # alongside base.
  flake.homeConfigurations.laptop = withSystem "x86_64-linux" ({ system, ... }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs-hm.legacyPackages.${system};
      modules = [ self.modules.homeManager.base ];
      extraSpecialArgs = { inherit inputs; };
    });
}
