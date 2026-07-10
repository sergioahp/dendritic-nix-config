{ ... }: {
  # vmVariant only applies to `nixos-rebuild build-vm`, never a real build,
  # so these test conveniences can't leak onto actual hardware.
  flake.nixosModules.base = {
    virtualisation.vmVariant = {
      services.getty.autologinUser = "root";   # boot straight to a root shell
      virtualisation = {
        graphics = false;                       # serial console in this terminal, no window
        memorySize = 2048;
        cores = 2;
      };
    };
  };
}
