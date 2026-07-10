{ self, inputs, withSystem, ... }: {
  flake.homeConfigurations.desktop = withSystem "x86_64-linux" ({ pkgs, ... }:
    inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      {
          home.username = "admin";
          home.homeDirectory = "/home/admin";
          home.stateVersion = "25.11";
      }
    ];
    extraSpecialArgs = { inherit inputs; };
  });
}
