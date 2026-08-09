{ self, inputs, lib, config, ... }: {
  # Two axes multiplied into nixosConfigurations:
  #
  #   machines (identity/hardware)  x  tiers (capability stack)
  #
  # The machine is written once and shared by every tier built from it, so when
  # real hardware config lands it isn't duplicated per tier. The tier is the
  # list of capability modules stacked on top: headless is the cli-only system
  # (base + tor, opted in for both machines), graphical adds the GUI stack
  # (SDDM + keyring + a windowed VM variant). The tier's attr name is the suffix
  # appended to the machine name, so "" yields the plain machine and
  # "-graphical" its GUI sibling:
  #
  #   desktop  desktop-graphical  laptop  laptop-graphical

  # machines was a let binding until the private submodule needed to add one.
  # As an option it merges across files like everything else here, so
  # modules/private can define a host with real hardware in it and the
  # multiplication below stays public. Deliberately NOT under flake.*: these
  # are deferred modules, an assembly detail rather than something worth
  # exporting. flake.homeConfigurations is an output only because
  # `home-manager switch --flake .#name` looks it up there; nothing looks
  # machines up from outside.
  options.machines = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.deferredModule;
    default = { };
    description = ''
      Per-machine identity and hardware, keyed by machine name. Each entry is
      multiplied by every tier to produce the nixosConfigurations.
    '';
  };

  config = {
    machines = {
      desktop = { networking.hostName = "desktop"; nixpkgs.hostPlatform = "x86_64-linux"; };
      laptop = { networking.hostName = "laptop"; nixpkgs.hostPlatform = "x86_64-linux"; };
    };

    flake.nixosConfigurations =
      let
        headless = [ self.nixosModules.base self.nixosModules.tor ];
        tiers = {
          "" = headless;
          "-graphical" = headless ++ [ self.nixosModules.graphical ];
        };

        mkSystem = machine: tierModules:
          inputs.nixpkgs.lib.nixosSystem { modules = tierModules ++ [ machine ]; };

        real = lib.concatMapAttrs
          (name: machine:
            lib.mapAttrs'
              (suffix: tierModules:
                lib.nameValuePair "${name}${suffix}" (mkSystem machine tierModules))
              tiers)
          config.machines;

        # Hosts whose machine module lives in modules/private. Listed here, in
        # the public tree, on purpose: the point is to produce a useful error
        # exactly when the private tree is NOT visible, which is precisely when
        # nothing private can supply the list. A hostname is the least
        # sensitive thing we hold.
        privateHosts = [ "nixd" ];

        missing = lib.filter (name: !(lib.hasAttr name config.machines)) privateHosts;

        # Fail closed. Without this the host just vanishes from
        # nixosConfigurations and nixos-rebuild reports a bare "attribute does
        # not exist", which reads like a typo rather than one of the three
        # things that actually cause it. throw is lazy, so `nix eval
        # .#nixosConfigurations --apply builtins.attrNames` still lists the
        # name; only using it fails.
        stubMessage = name: ''
          machine "${name}" is defined in the private submodule, and nix cannot see it.

            missing flag       nixos-rebuild switch --flake '.?submodules=1#${name}'
            not checked out    git submodule update --init
            new file untracked git -C modules/private add <file>
                               (nix ignores untracked files, silently)
        '';

        stubs = lib.listToAttrs (lib.concatMap
          (name: map
            (suffix: lib.nameValuePair "${name}${suffix}" (throw (stubMessage name)))
            (lib.attrNames tiers))
          missing);
      in
      stubs // real;
  };
}
