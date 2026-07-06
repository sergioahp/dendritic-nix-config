{ lib, ... }: {
  perSystem = { config, pkgs, ... }:
    let
      # the merged aliases from every module, minus the ones claude runs
      # constantly and should get stock behavior for
      claude-aliases = removeAttrs config.zsh.shellAliases [
        "cat" "ls" "mv" "rm" "cp" "mkdir" "cd" "pwd" "grep" "find" "echo"
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
        inherit (pkgs.claude-code) name meta;
        paths = [ pkgs.claude-code ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/claude \
            --set CLAUDE_CODE_SHELL ${claude-bash}/bin/bash
        '';
      };
    };
}
