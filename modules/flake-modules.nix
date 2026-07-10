{ inputs, ... }: {
  # Enables flake.modules.<class>.<name>: deferredModule groups that merge
  # across files, one module class per outer key. flake-parts ships a builtin
  # flake.nixosModules but no home-manager equivalent, so this is how the home
  # layer gets the same merge-across-files behaviour the nixos base relies on.
  imports = [ inputs.flake-parts.flakeModules.modules ];
}
