{ ... }: {
  flake.nixosModules.tailscale = {
    services.tailscale = {
      enable = true;
      # Opens the UDP port tailscaled uses for direct peer-to-peer connections.
      # Without it the tailnet still works, but falls back to relaying through
      # DERP servers more often, which costs latency.
      openFirewall = true;
    };

    # Traffic arriving over the tailnet is already authenticated by WireGuard,
    # so a service is reachable there without opening its port on the physical
    # interface -- which, on a host with a globally routable IPv6 address, would
    # expose it to the internet and not just the LAN. This is what makes sshd
    # reachable on a host that keeps 22 closed.
    #
    # Kept with the daemon rather than pushed out to each machine because
    # "tailscale0" names nothing on a host that isn't running tailscaled. The
    # cost of that is worth saying out loud: importing this module trusts every
    # peer on the tailnet, which is the intent, not a side effect.
    networking.firewall.trustedInterfaces = [ "tailscale0" ];
  };
}
