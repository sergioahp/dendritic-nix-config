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
  flake.nixosModules.xremap = { config, lib, ... }: {
    # A list rather than a hardcoded "admin" because msi runs two daily-driver
    # accounts (work and personal as separate unix users) and both sit at the
    # same keyboard. The membership is per-user and not per-session: whoever is
    # listed can read every input device on the box whenever they are logged
    # in, which is exactly the privilege xremap needs and exactly why this is
    # spelled out per machine rather than handed to every account by default.
    options.xremap.users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "admin" ];
      description = ''
        Users allowed to run the session xremap daemon, i.e. granted the input
        and uinput group memberships it needs.
      '';
    };

    config = {
      hardware.uinput.enable = true;
      users.groups.input.members = config.xremap.users;
      users.groups.uinput.members = config.xremap.users;
    };
  };
}
