{ self, inputs, lib, ... }: {
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
  flake.nixosConfigurations =
    let
      machines = {
        desktop = { networking.hostName = "desktop"; nixpkgs.hostPlatform = "x86_64-linux"; };
        laptop = { networking.hostName = "laptop"; nixpkgs.hostPlatform = "x86_64-linux"; };
      };

      headless = [ self.nixosModules.base self.nixosModules.tor ];
      tiers = {
        "" = headless;
        "-graphical" = headless ++ [ self.nixosModules.graphical ];
      };

      mkSystem = machine: tierModules:
        inputs.nixpkgs.lib.nixosSystem { modules = tierModules ++ [ machine ]; };
    in
    lib.concatMapAttrs
      (name: machine:
        lib.mapAttrs'
          (suffix: tierModules:
            lib.nameValuePair "${name}${suffix}" (mkSystem machine tierModules))
          tiers)
      machines;
}
