{ self, ... }: {
  # msi: an MSI Modern 14, Ryzen 7 7730U, 16G, wifi-only. The second daily
  # driver, and the first host in this repo installed from scratch with the
  # disk layout the repo actually wants (LUKS2 + btrfs subvolumes + an
  # encrypted swap partition that hibernation resumes from).
  #
  # It was installed under the hostname "nixd", which is wrong twice over: the
  # d stands for desktop and this is a laptop, and nixd is already the name of
  # the real desktop -- two hosts answering to one name on the same LAN. The
  # name changes here, and the first switch onto this config renames the
  # running machine.
  #
  # The hardware half (LUKS uuids, subvolumes, swap) merges in from
  # modules/private/msi.nix: machines is a lazyAttrsOf deferredModule, so both
  # definitions of machines.msi combine into one machine. Everything explicable
  # stays on this side.
  machines.msi = { pkgs, ... }: {
    imports = [
      self.nixosModules.boot-efi
      self.nixosModules.xremap
      self.nixosModules.bluetooth
    ];

    networking.hostName = "msi";

    # Both accounts sit at this machine's own keyboard, so both need the input
    # and uinput memberships the session xremap daemon runs on. The remaps
    # themselves are per-user config in the home layer; this is only the
    # permission to grab a keyboard.
    xremap.users = [ "admin" "personal" ];

    # Installed on 26.05, unlike every host that came before it. See the
    # mkDefault in nixos/base.nix.
    system.stateVersion = "26.05";

    # 7730U silicon and its wifi are newer than the kernel a stable channel
    # would pick. Nothing here has been narrowed down to a specific fix; it is
    # the standard opening move on a recent laptop, and cheap to drop later if
    # a release kernel turns out to be enough.
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # Wifi is the only link this machine has (there is no ethernet port), so
    # NetworkManager is not a convenience here, it is the network. Its
    # connections live in /etc/NetworkManager/system-connections, outside nix,
    # which is why a rebuild never costs the wifi password.
    networking.networkmanager.enable = true;

    # NetworkManager-wait-online holds up network-online.target until a link is
    # actually up, and on wifi that means waiting out association, DHCP and its
    # own 30s timeout on every boot. Nothing here is ordered after
    # network-online.target: sshd does not need it (it binds and waits),
    # NetworkManager brings the wifi up on its own schedule regardless, and the
    # cost of being wrong is a service starting a few seconds before the link,
    # not a service that never starts.
    #
    # Revisit if this host ever mounts a network filesystem at boot or runs
    # something that genuinely declares After=network-online.target, since
    # those are the two cases the unit exists for.
    systemd.services.NetworkManager-wait-online.enable = false;

    # 16G, and the workload is agents holding several toolchains resident at
    # once. zstd over the lzo/lz4 family: 2.25x against ~1.75x on this box's
    # own benchmark, at 185 MB/s compress, which a 16-thread part absorbs
    # without noticing. deflate compresses marginally better (2.30x) at
    # 33 MB/s, which is exactly the wrong tradeoff for a swap tier. Left at the
    # module's default 50% of RAM. The encrypted swap partition sits behind
    # this as the slower second tier, and is what hibernation writes to.
    zramSwap = {
      enable = true;
      algorithm = "zstd";
    };

    # Block-level dedup for the single btrfs filesystem that holds every
    # subvolume (@, @home, @nix, @docker, @libvirtimages, @snapshots, ...).
    # bees works on the whole fs, so one instance covers all of them; a
    # second instance for a subvolume of the same fs would be wrong.
    #
    # spec is the mountpoint, not a UUID or /dev/mapper/cryptroot: a bare
    # path lets systemd start beesd only once the fs is unlocked and
    # mounted, and keeps this public module free of the disk identifiers
    # that live in modules/private/msi.nix.
    #
    # Started at the upstream-default 1024MB/5.0, copied from nixd without
    # accounting for the difference in hardware. The first real run showed
    # both were too rich for this machine: CPU ramped to ~70%, and `btrfs
    # filesystem usage /` after that run put actual data at 8.29GiB (fresh
    # install), nowhere near the 1TB this box's raw capacity would suggest --
    # nixd's ratio was sized off actual usage, this one was sized off the
    # disk. Halved both: 512MB is still wildly oversized for 8GiB of data (it
    # was never the binding constraint), but this box is 16G of RAM against
    # nixd's 32G, half already claimed by zram, and other workloads here are
    # expected to want more of that RAM back over time -- so the mlock
    # footprint matters more here than the dedup granularity does.
    services.beesd.filesystems.root = {
      spec = "/";
      hashTableSizeMB = 512;
      # Halved alongside the table size for the same reason: a laptop doing
      # interactive work wants the scanner backing off sooner, not staying
      # at nixd's desktop-sized headroom.
      extraOptions = [ "--loadavg-target" "2.5" ];
    };

    # Backlight control. Only on this machine: nixd drives desktop monitors,
    # which have no kernel backlight device at all.
    #
    # No udev rule and no video group needed -- current brightnessctl talks to
    # logind rather than writing sysfs directly, which is why the old
    # hardware.brightnessctl module was removed from nixpkgs.
    #
    # Careful with 100%: amdgpu_bl1 reports max_brightness = 65535, but writing
    # exactly 65535 wraps to 0 in the hardware register and the panel drops to
    # minimum. That is why this machine shipped looking "super dim" while
    # brightness read max, and why it came back dim every boot --
    # systemd-backlight faithfully restored the broken value it had saved.
    # `brightnessctl set 100%` writes 65535 and will reproduce it; stay a step
    # below.
    environment.systemPackages = [ pkgs.brightnessctl ];

    # This machine is administered over ssh with the lid shut, and the stock
    # laptop reflex -- suspend on lid close -- drops the connection mid-command
    # every time. Suspending on purpose still works, this only unbinds the
    # switch. Note systemd-logind is deliberately not restarted by
    # `nixos-rebuild switch` (it would kill live sessions), so this takes
    # effect on reboot or after an explicit `systemctl restart systemd-logind`.
    services.logind.settings.Login.HandleLidSwitch = "ignore";

    # No tailnet on this host, so inbound ssh arrives on the LAN interface and
    # 22 has to be open on it. base keeps it shut and key-only; this reopens
    # the port, not password auth -- which stays off, so the authorized_keys
    # list on base is the entire way in.
    services.openssh.openFirewall = true;

    # A second daily-driver account, and the reason this machine exists in the
    # shape it does: work and personal live in separate unix users so an agent
    # running under one cannot read the other's files, ssh keys or tokens.
    # Nothing enforces that beyond ordinary unix permissions, which is the
    # point -- it is a boundary that already exists rather than a new mechanism
    # to maintain. No authorized_keys: this account is used at the keyboard.
    users.users.personal = {
      isNormalUser = true;
      shell = pkgs.zsh;
    };
  };
}
