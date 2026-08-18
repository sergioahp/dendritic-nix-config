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

    # Block-level dedup for the single btrfs filesystem that holds every
    # subvolume (@, @home, @nix, @docker, @libvirtimages, @persist, ...). bees
    # works on the whole fs, so one instance covers all of them; a second
    # instance for a subvolume of the same fs would be wrong.
    #
    # spec is the mountpoint, not the UUID: a bare path lets systemd start
    # beesd only once the fs is actually mounted, and keeps this public
    # module free of the disk identifiers that live in modules/private.
    #
    # Sizing: ~1TB of data on the fs. The hash table is mlocked, and the
    # ratio of table size to data size sets the smallest duplicate extent
    # that can be recognized: 1GB for 1TB means aligned 16KB blocks, 4GB
    # would get down to the 4KB minimum. 1GB of the 32GB of RAM is the sane
    # end of that trade.
    services.beesd.filesystems.root = {
      spec = "/";
      hashTableSizeMB = 1024;
      # Desktop, not a NAS: back off the scan when the box is already busy
      # instead of competing with interactive work for the 12 threads.
      extraOptions = [ "--loadavg-target" "5.0" ];
    };

    # nixd-graphical evaluates today but is not what this host boots -- it
    # still runs the pre-dendritic ~/nixos config, and that config carries two
    # workarounds for a GTX 760 (Kepler, nouveau) that the graphical tier
    # deliberately does not: hyprland held at v0.49.0, and mesa from a 25.11
    # snapshot. Both belong here, on the machine, when the graphical half
    # migrates -- programs.hyprland.package plus hardware.graphics.package,
    # from inputs whose revisions live in flake.lock rather than being written
    # into flake.nix. Booting nixd-graphical as it stands would put the newer
    # compositor back on the GPU that froze on it.
  };
}
