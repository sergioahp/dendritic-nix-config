{ lib, ... }: {
  perSystem = { config, pkgs, inputs', ... }:
    let
      # From llm-agents.nix rather than nixpkgs: new claude-code releases show up
      # here as soon as they're GA, instead of lagging the nixpkgs merge queue.
      claude-code-pkg = inputs'.llm-agents.packages.claude-code;

      # the merged aliases from every module, minus the ones claude runs
      # constantly and should get stock behavior for.
      # tree is in the list because eza -T is not a drop-in for it: claude
      # reads that output, and the two disagree on layout and flags.
      claude-aliases = removeAttrs config.zsh.shellAliases [
        "cat" "ls" "tree" "mv" "rm" "cp" "mkdir" "cd" "pwd" "grep" "find" "echo"
      ];

      aliasesStr = lib.concatStringsSep "\n" (lib.mapAttrsToList
        (k: v: "alias -- ${lib.escapeShellArg k}=${lib.escapeShellArg v}")
        claude-aliases);

      claude-bashenv = pkgs.writeText "claude-bashenv" /* bash */ ''
        shopt -s expand_aliases globstar
        ${aliasesStr}
        unset BASH_ENV
      '';

      claude-bash = pkgs.symlinkJoin {
        name = "claude-bash";
        paths = [ pkgs.bashInteractive ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/bash --set BASH_ENV ${claude-bashenv}
        '';
      };
    in {
      config.packages.claude-code = pkgs.symlinkJoin {
        inherit (claude-code-pkg) name meta;
        paths = [ claude-code-pkg ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/claude \
            --set CLAUDE_CODE_SHELL ${claude-bash}/bin/bash
        '';
      };
    };
}
