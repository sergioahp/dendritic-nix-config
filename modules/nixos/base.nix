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

    time.timeZone = "America/Mexico_City";
    i18n.defaultLocale = "en_US.UTF-8";
  };
}
