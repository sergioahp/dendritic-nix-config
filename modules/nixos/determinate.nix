{ inputs, ... }: {
  # applies to every host on base (laptop and desktop)
  flake.nixosModules.base = {
    imports = [ inputs.determinate.nixosModules.default ];
  };
}
