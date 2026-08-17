{ ... }: {
  # System half of xremap. The daemon itself runs in the user session
  # (home-manager's services.xremap), so all NixOS has to supply is permission
  # for a non-root process to read the real keyboards and write a synthetic one:
  #
  #   input   read /dev/input/event* -- the physical devices xremap grabs
  #   uinput  write /dev/uinput      -- the virtual device it emits remapped keys on
  #
  # hardware.uinput.enable loads the kernel module and ships the udev rule that
  # hands /dev/uinput to the uinput group; the memberships are what let the
  # session user through the two doors that rule opens.
  flake.nixosModules.xremap = {
    hardware.uinput.enable = true;
    users.groups.input.members = [ "admin" ];
    users.groups.uinput.members = [ "admin" ];
  };
}
