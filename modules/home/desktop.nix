{ self, inputs, withSystem, ... }: {
  flake.homeConfigurations.desktop = withSystem "x86_64-linux" ({ system, ... }:
    inputs.home-manager.lib.homeManagerConfiguration {
      # User packages ride nixpkgs-hm (the faster-moving nixpkgs), not the
      # system's nixos-unstable that withSystem's pkgs would hand us. home-manager
      # ignores the nixpkgs.* options when pkgs is passed in, so the overlay and
      # allowUnfree have to go on the import here.
      pkgs = import inputs.nixpkgs-hm {
        inherit system;
        overlays = [ self.overlays.default ];
        config.allowUnfree = true; # claude-code
      };
      modules = [ self.modules.homeManager.base ];
      extraSpecialArgs = { inherit inputs; };
    });
}
