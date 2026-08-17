{ ... }: {
  flake.nixosModules.base = { lib, ... }: {
    # stateVersion records the release a machine was *installed* under, so it
    # is a per-machine fact and not a repo-wide one. mkDefault because the
    # hosts that predate this line were all installed on 25.11 and there is no
    # reason to make each of them restate it; a machine installed later
    # overrides it (see machines/msi.nix).
    system.stateVersion = lib.mkDefault "25.11";

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
      # |> in nix expressions. Worth having everywhere rather than per-shell:
      # an expression that uses it fails to *parse* without the flag, so a flag
      # that is only sometimes on means code that only sometimes evaluates.
      "pipe-operators"
      # Multi-threaded evaluation. Determinate ships eval-cores = 0 (all cores)
      # in its own nix.conf, so enabling the feature is the whole opt-in.
      "parallel-eval"
    ];

    # Hosts in this repo are deployed to with
    # `nixos-rebuild --target-host admin@<host>`, which runs nix-copy-closure
    # as admin over ssh. The receiving daemon refuses unsigned store paths from
    # an untrusted user, and a locally built system closure is full of unsigned
    # paths (etc-fstab, the unit files, the toplevel itself), so without this
    # the copy dies on the first one.
    #
    # trusted-users rather than require-sigs = false, which is the other way to
    # make the error go away: that one disables signature checking for every
    # path from every source, including substituters, on a machine that then
    # trusts whatever any of them hands it. This grants the same power to
    # exactly one named account instead.
    #
    # Be clear about what this costs, because it is a real widening and not a
    # bookkeeping detail. A trusted user can insert arbitrary paths into the
    # store and override sandbox and substituter settings, which the Nix manual
    # treats as equivalent to root. admin's sudo asks for a password, so before
    # this line an attacker holding only the ssh key got a shell and had to
    # stop there. After it, the key alone is enough to reach root. Password
    # auth is off, so that key is the whole of the boundary.
    #
    # The narrower option, if that trade stops being worth it: leave admin
    # untrusted, put a deploy key's public half in trusted-public-keys, and
    # sign the closure locally before pushing it
    # (`nix store sign -k <secret> -r <toplevel>`). Signature trust only says
    # "accept paths this key vouched for" and grants no root, at the cost of a
    # signing step on every deploy.
    # Just admin: this option is a list that merges, and the NixOS default
    # already contributes root, so naming it here only prints it twice.
    nix.settings.trusted-users = [ "admin" ];

    time.timeZone = "America/Mexico_City";
    i18n.defaultLocale = "en_US.UTF-8";
  };
}
