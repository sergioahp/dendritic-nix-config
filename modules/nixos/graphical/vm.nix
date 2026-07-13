{ lib, ... }: {
  # base's vmVariant runs the VM headless (serial console, graphics off) for the
  # ssh test. The graphical tier flips graphics back on so `nixos-rebuild
  # build-vm` opens a QEMU window and you can see the SDDM greeter, and bumps
  # the RAM enough for the wayland greeter to render. vmVariant only applies to
  # build-vm, so none of this leaks onto real hardware.
  flake.nixosModules.graphical = {
    virtualisation.vmVariant = {
      virtualisation = {
        graphics = lib.mkForce true;
        memorySize = lib.mkForce 4096;
      };
      # skip the SDDM password prompt in the test VM
      services.displayManager.autoLogin = {
        enable = true;
        user = "admin";
      };
    };
  };
}
