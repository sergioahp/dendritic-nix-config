{ lib, ... }: {
  perSystem = { pkgs, config, self', ... }:
    let
      # only the env_var module; starship merges this over its built-in
      # defaults, so the full default prompt stays and we just gain an
      # indicator whenever DEV_SHELL is set (i.e. inside this shell).
      starship-config = pkgs.writeText "starship.toml" /* toml */ ''
        [env_var.DEV_SHELL]
        variable = "DEV_SHELL"
        # "dev:" prefix + yellow so it does not blend into the cyan
        # directory module (which shows this repo's name too)
        format = "[dev:$env_value]($style) "
        style = "bold yellow"
      '';
    in {
    # The same seam zsh.initExtra is: something that belongs to this shell but
    # is decided elsewhere, by a module that may not be checked out at all.
    # Lines rather than a string so several contributors merge.
    options.devShell.hookExtra = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Shell code contributed by any module, run at the top of devShells.dev's
        shellHook -- before the exec into zsh, so it also reaches
        `nix develop .#dev --command ...`, which never sources a zshrc.
      '';
    };

    config.devShells.dev = pkgs.mkShell {
      packages = [
        # wrapped tools, each carrying its own config
        self'.packages.zsh
        self'.packages.fzf
        self'.packages.claude-code
        self'.packages.codex
        self'.packages.tmux
        self'.packages.btop

        pkgs.git
        pkgs.gh

        # Editing modules/auth-common/secrets.yaml. Here rather than on the
        # system: it is a thing you do while working on this repo, not
        # something a host needs installed to decrypt at boot (sops-nix carries
        # its own copy for that).
        pkgs.sops

        # Wrapped nvim carrying every external tool ~/.config/nvim needs on its
        # own PATH (see modules/neovim.nix); the raw deps below put the same
        # tools (LSPs, tree-sitter, typst, ...) on the interactive shell too.
        self'.packages.neovim

        pkgs.ripgrep
        pkgs.fd

        pkgs.wget
        pkgs.aria2

        pkgs.atool
        pkgs.unzip
        pkgs.unrar
        pkgs.rsync

        pkgs.eza
        pkgs.bat
        pkgs.yazi
        pkgs.tree
        pkgs.dust
        pkgs.btop

        pkgs.file

        pkgs.jq
      ]
      # nvim's external tools on the interactive PATH too (LSPs, tree-sitter,
      # typst, build toolchains). Defined once in modules/neovim.nix.
      ++ config.neovim.runtimeDeps;
      env = {
        # read by the starship env_var module so the prompt shows we're here
        DEV_SHELL = "dendritic-cli";
        # repo-owned config so the indicator works on remote boxes too,
        # not just where a personal starship.toml exists
        STARSHIP_CONFIG = "${starship-config}";
        # mirrors cli-only for now; fold both into a shared option once the
        # abstraction TODO in cli-shell.nix lands
        EDITOR = "${self'.packages.neovim}/bin/nvim";
        MANPAGER = "${self'.packages.neovim}/bin/nvim +Man!=";
      };
      shellHook = ''
        ${config.devShell.hookExtra}

        # nix develop drops into bash; hop into our configured zsh instead.
        # guard on interactivity so `nix develop --command ...` and direnv
        # (both non-interactive) still get plain bash and skip the exec.
        if [[ $- == *i* ]]; then
          exec ${self'.packages.zsh}/bin/zsh
        fi
      '';
    };
  };
}
