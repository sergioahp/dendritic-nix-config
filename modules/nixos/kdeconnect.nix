{ ... }: {
  # System half of KDE Connect. kdeconnectd runs in the user session
  # (home-manager's services.kdeconnect), so the only thing it needs from NixOS
  # is the firewall. The protocol picks a fresh port per connection out of
  # 1714-1764 and uses both transports -- UDP for the broadcast that discovers
  # peers on the LAN, TCP for everything after -- so the whole range has to be
  # open on both.
  flake.nixosModules.kdeconnect = {
    networking.firewall = {
      allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
      allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
    };
  };
}
