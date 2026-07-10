{ lib, inputs, ... }: {
  perSystem = { pkgs, inputs', ... }:
    let
      # From llm-agents.nix rather than nixpkgs: new codex releases show up here
      # as soon as they're GA, instead of lagging the nixpkgs merge queue.
      codex-pkg = inputs'.llm-agents.packages.codex;

      # TEMPORARY shim, remove once numtide/llm-agents.nix#6631 lands: their
      # codex package misses the codex-code-mode-host helper that codex >= 0.144
      # spawns for every shell command, breaking all command execution. Upstream
      # ships it prebuilt (static musl), so fetch it (codex-code-mode-host-bin
      # flake input, pinned by flake.lock) and point codex at it via
      # CODEX_CODE_MODE_HOST_PATH instead of recompiling the rust workspace. The
      # input URL pins the host version; the assert fails loudly when llm-agents
      # bumps codex - check whether the shim is still needed before bumping the
      # input URL in flake.nix.
      hostVersion = "0.144.1";
      hostBin = pkgs.runCommand "codex-code-mode-host-${hostVersion}" { } ''
        mkdir -p $out/bin
        install -m755 ${inputs.codex-code-mode-host-bin}/codex-code-mode-host-* \
          $out/bin/codex-code-mode-host
      '';
    in {
      config.packages.codex =
        assert lib.assertMsg (codex-pkg.version == hostVersion)
          ("codex-code-mode-host-bin input is pinned to ${hostVersion} but "
            + "llm-agents' codex is ${codex-pkg.version}; if "
            + "numtide/llm-agents.nix#6631 landed drop this shim, otherwise "
            + "bump the input URL in flake.nix and hostVersion here");
        pkgs.symlinkJoin {
          inherit (codex-pkg) name meta;
          paths = [ codex-pkg ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/codex \
              --set CODEX_CODE_MODE_HOST_PATH ${hostBin}/bin/codex-code-mode-host
          '';
        };
    };
}
