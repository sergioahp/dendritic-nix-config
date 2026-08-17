{ ... }: {
  # Deliberately NOT on base: which bootloader a host needs is a property of
  # its firmware, the same kind of fact as fileSystems or hostPlatform. A host
  # opts in from its machine module. Putting it on base would mean a future
  # BIOS or VPS host has to unpick it with mkForce, and an override that has to
  # fight a default is exactly the kind of silent wrong config this repo tries
  # to make impossible.
  #
  # canTouchEfiVariables lets the installer write its own boot entry via
  # efivars instead of relying on the firmware finding the fallback path.
  flake.nixosModules.boot-efi = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
