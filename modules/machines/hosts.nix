{ self, inputs, lib, config, ... }: {
  # Two axes multiplied into nixosConfigurations:
  #
  #   machines (identity/hardware)  x  tiers (capability stack)
  #
  # The machine is written once and shared by every tier built from it, so when
  # real hardware config lands it isn't duplicated per tier. A machine also
  # imports the capabilities that follow from its own hardware and place -- a
  # keyboard worth remapping, a phone to pair with, a tailnet to join -- since
  # those don't generalise to every host of the same shape. The tier is the
  # list of capability modules stacked on top: headless is the cli-only system
  # (base + tor, opted in for every machine), graphical adds the GUI stack
  # (SDDM + keyring + a windowed VM variant). The tier's attr name is the suffix
  # appended to the machine name, so "" yields the plain machine and
  # "-graphical" its GUI sibling:
  #
  #   nixd  nixd-graphical  laptop  laptop-graphical  vm  vm-graphical

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
      # Not a machine anyone owns: no hardware, exists to be booted with
      # `nixos-rebuild build-vm --flake .#vm` (or .#vm-graphical to get a QEMU
      # window and the SDDM greeter). It was called "desktop" and read as a
      # second entry for the real desktop, which is nixd -- the name was the
      # whole confusion. Reachable over the port vm-test.nix forwards, so it
      # wants plain ssh and no tailnet.
      #
      # xremap is here because trying out remaps is work that gets handed to
      # agents, and a throwaway VM is where that belongs rather than on the
      # keyboard you are currently typing on.
      vm = {
        imports = [ self.nixosModules.xremap ];
        networking.hostName = "vm";
        nixpkgs.hostPlatform = "x86_64-linux";
      };
      laptop = {
        # No tailscale: this host isn't on the tailnet, and the tailscale module
        # trusts tailscale0 in the firewall, so importing it for the daemon alone
        # would buy a trust decision it has no use for.
        imports = [ self.nixosModules.xremap self.nixosModules.kdeconnect ];

        # The counterpart to that: with no tailnet to arrive over, nixd -> laptop
        # ssh comes in on the LAN, so 22 has to be open on the physical
        # interface. base keeps it shut and key-only; this reopens the port, not
        # password auth.
        services.openssh.openFirewall = true;

        networking.hostName = "laptop";
        nixpkgs.hostPlatform = "x86_64-linux";
      };
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

        # Checks for the file, not for `config.machines ? name`. A private host
        # is declared in two halves that merge - modules/machines/<name>.nix
        # (public capabilities) and modules/private/<name>.nix (hardware facts)
        # - so the attribute exists whether or not the submodule is visible and
        # proves nothing on its own. The convention this relies on: one file per
        # private host, named after the host.
        missing = lib.filter
          (name: !(builtins.pathExists (../private + "/${name}.nix")))
          privateHosts;

        # Fail closed. Without this the host just vanishes from
        # nixosConfigurations and nixos-rebuild reports a bare "attribute does
        # not exist", which reads like a typo rather than one of the three
        # things that actually cause it. throw is lazy, so `nix eval
        # .#nixosConfigurations --apply builtins.attrNames` still lists the
        # name; only using it fails.
        stubMessage = name: ''
          machine "${name}" gets its hardware from modules/private/${name}.nix,
          and nix cannot see that file.

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
      # stubs last: the public half of a private machine always lands in `real`,
      # so the stub has to win for the hosts whose private half is missing.
      # When the submodule is visible `stubs` is empty and this is just `real`.
      real // stubs;
  };
}
