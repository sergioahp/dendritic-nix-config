{ self, inputs, ... }: {
  # Home Manager is part of every NixOS tier, not a second deployment step.
  # Individual tiers append shared user modules below: base gives every managed
  # account the repair/CLI environment, and graphical adds its session programs.
  flake.nixosModules.base = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager = {
      # System and home packages intentionally resolve through one overlaid
      # package set. This makes a nixos-rebuild switch the complete deployment
      # transaction and keeps the wrapped CLI on both PATHs.
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs; };
      sharedModules = [ self.modules.homeManager.base ];
      users.admin = {
        home.username = "admin";
        home.homeDirectory = "/home/admin";
      };
    };
  };
}
