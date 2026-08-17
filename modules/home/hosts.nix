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
  # The generations are currently identical apart from the username, since the
  # home layer is deliberately still barebones -- the llm agents and the
  # wrapped cli, nothing else. The machine axis is here because that is what
  # diverges first (monitors, cursor, gpu accel), the same way it does on
  # modules/machines/hosts.nix.
  flake.homeConfigurations =
    let
      users = {
        nixd = [ "admin" ];
        laptop = [ "admin" ];
        msi = [ "admin" "personal" ];
      };

      mkHome = user: withSystem "x86_64-linux" ({ system, ... }:
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
          ];
          extraSpecialArgs = { inherit inputs; };
        });
    in
    lib.concatMapAttrs
      (machine: machineUsers:
        lib.listToAttrs (map
          (user: lib.nameValuePair "${user}@${machine}" (mkHome user))
          machineUsers))
      users
    // {
      # The names this repo used when admin was the only user. Kept so
      # `home-manager switch --flake .#desktop` does not break; drop them once
      # the user@machine names are in muscle memory.
      desktop = mkHome "admin";
      laptop = mkHome "admin";
    };
}
