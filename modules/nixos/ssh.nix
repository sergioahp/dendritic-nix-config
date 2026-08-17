{ ... }: {
  flake.nixosModules.base = { lib, ... }: {
    services.openssh = {
      enable = true;
      # NixOS opens 22 on every interface by default, which is the wrong default
      # for a host holding a globally routable IPv6 address: it puts sshd on the
      # internet, not on the LAN one was picturing. Closed here so reachability
      # is something each host states -- by joining a tailnet (tailscale.nix
      # trusts tailscale0) or by opening the port on purpose. mkDefault rather
      # than a plain false so the host that wants LAN logins says `true` instead
      # of having to mkForce its way past a decision made for it.
      openFirewall = lib.mkDefault false;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };
}
