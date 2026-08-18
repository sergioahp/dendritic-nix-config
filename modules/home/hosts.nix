{ self, inputs, lib, withSystem, ... }: {
  # Which (machine, user) pairs get a home generation.
  #
  # Only non-root users. root's environment belongs to the system closure, and
  # a home generation for it would be a second, sudo-requiring thing to
  # activate for an account nobody logs into interactively.
  #
  # Written out rather than derived from config.machines: a machine declaring
  # a user account says nothing about whether a person logs into it and wants
  # a home generation. msi has two because work and personal are separated by
  # unix user there, and both are daily drivers.
  #
  # Tiers mirror the NixOS axis rather than making graphical programs an
  # accidental property of a machine. Thus every target has a lean home
  # generation for repair and remote work, while graphical targets add only
  # the session-owned programs. vm is included because its graphical variant
  # is where the initial session wiring is exercised safely.
  flake.homeConfigurations =
    let
      users = {
        nixd = [ "admin" ];
        laptop = [ "admin" ];
        msi = [ "admin" "personal" ];
        vm = [ "admin" ];
      };

      tiers = {
        "" = [ ];
        "-graphical" = [ self.modules.homeManager.graphical ];
      };

      mkHome = user: tierModules: withSystem "x86_64-linux" ({ system, ... }:
        inputs.home-manager.lib.homeManagerConfiguration {
          # User packages ride nixpkgs-hm (the faster-moving nixpkgs), not the
          # system's nixos-unstable that withSystem's pkgs would hand us.
          # home-manager ignores the nixpkgs.* options when pkgs is passed in,
          # so the overlay and allowUnfree have to go on the import here.
          pkgs = import inputs.nixpkgs-hm {
            inherit system;
            overlays = [ self.overlays.default ];
            config.allowUnfree = true; # claude-code
          };
          modules = [
            self.modules.homeManager.base
            {
              home.username = user;
              home.homeDirectory = "/home/${user}";
            }
          ] ++ tierModules;
          extraSpecialArgs = { inherit inputs; };
        });
    in
    lib.concatMapAttrs
      (machine: machineUsers:
        lib.concatMapAttrs
          (suffix: tierModules:
            lib.listToAttrs (map
              (user: lib.nameValuePair "${user}@${machine}${suffix}" (mkHome user tierModules))
              machineUsers))
          tiers)
      users
    // {
      # The old aliases name the non-graphical configurations, as they did
      # before tiers existed. Keep them until the explicit user@machine names
      # are in muscle memory.
      desktop = mkHome "admin" tiers."";
      laptop = mkHome "admin" tiers."";
    };
}
