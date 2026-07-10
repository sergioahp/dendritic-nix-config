{ self, inputs, withSystem, ... }: {
  # Identical to desktop for now; diverges later on screen, mouse, chrome gpu
  # accel and other host-specific bits, which will import a laptop-only module
  # alongside base.
  flake.homeConfigurations.laptop = withSystem "x86_64-linux" ({ system, ... }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs-hm {
        inherit system;
        overlays = [ self.overlays.default ];
        config.allowUnfree = true; # claude-code
      };
      modules = [ self.modules.homeManager.base ];
      extraSpecialArgs = { inherit inputs; };
    });
}
