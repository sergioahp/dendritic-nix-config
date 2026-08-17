{ ... }: {
  # vmVariant only applies to `nixos-rebuild build-vm`, never a real build,
  # so these test conveniences can't leak onto actual hardware.
  flake.nixosModules.base = {
    virtualisation.vmVariant = {
      services.getty.autologinUser = "root";   # boot straight to a root shell
      security.sudo.wheelNeedsPassword = false; # no password prompt in the test VM
      # ssh.nix keeps 22 shut on the physical interface, and QEMU's forwarded
      # port arrives on exactly that interface -- so without this the ssh test
      # below is testing a dropped packet. Real hosts are reachable over the
      # tailnet instead, which a build-vm has no equivalent of.
      services.openssh.openFirewall = true;
      determinate.enable = false;              # stock nix in the VM: lighter, cleaner ssh test
      virtualisation = {
        graphics = false;                       # serial console in this terminal, no window
        memorySize = 2048;
        cores = 2;
        forwardPorts = [
          # ssh into the running VM from the host: ssh -p 2222 admin@localhost
          { from = "host"; host.port = 2222; guest.port = 22; }
        ];
      };
    };
  };
}
