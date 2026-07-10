{ lib, ... }: {
  # flake-parts declares flake.nixosConfigurations but ships no home equivalent,
  # so without this the freeform flake type refuses to merge two hosts defined in
  # separate files (desktop.nix + laptop.nix collide). Mirror the upstream
  # nixosConfigurations declaration: lazyAttrsOf raw merges by host name.
  options.flake.homeConfigurations = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = ''
      Standalone home-manager configurations, activated sudo-less with
      `home-manager switch --flake .#<name>`.
    '';
  };
}
