{ ... }: {
  # llm-agents deliberately does NOT follow our nixpkgs (see flake.nix), so its
  # packages come pre-built against its own pinned nixpkgs. Point the daemon at
  # numtide's cache so claude-code and friends are substituted instead of built
  # from source. Determinate includes the NixOS-generated nix.conf from its own
  # /etc/nix/nix.conf, so nix.settings still applies here.
  # System-level rather than home so the substituter is available to the daemon
  # for every build (sudo rebuilds and sudoless home switches alike).
  flake.nixosModules.base = {
    nix.settings = {
      extra-substituters = [ "https://cache.numtide.com" ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
    };
  };
}
