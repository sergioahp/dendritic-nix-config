{ self, ... }: {
  # nixd's capability stack. The hardware facts (LUKS, subvolumes, swap) merge
  # in from modules/private/nixd.nix: machines is a lazyAttrsOf deferredModule,
  # so both definitions of machines.nixd combine into one machine.
  #
  # The split follows the public/private line the rest of the repo uses:
  # private holds identifiers, public holds anything explicable. Which
  # capabilities a host runs is explicable, and worth being able to review
  # without the submodule checked out.
  machines.nixd = {
    imports = [
      self.nixosModules.boot-efi
      self.nixosModules.tailscale
      self.nixosModules.xremap
      self.nixosModules.kdeconnect
    ];

    # Inbound ssh reaches nixd over the tailnet only -- base keeps 22 shut on
    # enp4s0, tailscale trusts tailscale0 -- so this key is the whole of the
    # network-facing attack surface. On the machine rather than on base because
    # it authorises one direction, laptop -> nixd, for the long-running jobs
    # that get started from the laptop; the return trip is a different key on a
    # different host.
    users.users.admin.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMcexlzC4/FjhelNXeLmNyB2vSP19iIXEoJo5rtsiVZU laptop -> nixd 2026-08-06"
    ];
  };
}
