{ lib, ... }: {
  perSystem = { config, pkgs, self', ... }:
    let
      aliasesStr = lib.concatStringsSep "\n" (lib.mapAttrsToList
        (k: v: "alias -- ${lib.escapeShellArg k}=${lib.escapeShellArg v}")
        config.zsh.shellAliases);

      base-config = pkgs.writeTextDir ".zshrc" /* zsh */ ''
      bindkey -v
      autoload -U compinit
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh


      # TODO: You should think about isolating this in a separate file
      HISTFILE=~/.zsh_history

      HISTSIZE=10000
      SAVEHIST=10000

      source <(${pkgs.fzf}/bin/fzf --zsh)

      # Set shell options
      set_opts=(
        HIST_FCNTL_LOCK APPEND_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE
        SHARE_HISTORY NO_EXTENDED_HISTORY NO_HIST_EXPIRE_DUPS_FIRST
        NO_HIST_FIND_NO_DUPS NO_HIST_IGNORE_ALL_DUPS NO_HIST_SAVE_NO_DUPS
      )
      for opt in "''${set_opts[@]}"; do
        setopt "$opt"
      done
      unset opt set_opts


      bindkey -v '^?' backward-delete-char
      bindkey ^K fzf-cd-widget
      bindkey ^J fzf-file-widget
      bindkey ^O autosuggest-accept
      autoload -U edit-command-line
      zle -N edit-command-line
      bindkey -M vicmd ^F edit-command-line
      bindkey ^F edit-command-line
      preexec() {
        local cmd="''${1%% *}"
        printf "\e]0;%s - %s\a" "$cmd" "''${PWD/#$HOME/~}"
      }
      if [[ $TERM != "dumb" ]]; then
        eval "$(${pkgs.starship}/bin/starship init zsh)"
      fi

      ${aliasesStr}

      ${config.zsh.initExtra}


      source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      '';
    in {
      options.zsh.shellAliases = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Aliases contributed by any part/module";
      };
      options.zsh.initExtra = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Extra zsh code";
      };
      config = {
        zsh.shellAliases = {
          sudo = "sudo ";
          g = "git";
          cat = "${pkgs.bat}/bin/bat --paging=never --style=plain";
          ls = "${pkgs.eza}/bin/eza";
          tree = "${pkgs.eza}/bin/eza -T";
          mv = "mv -i";
          rm = "rm -I";
        };
        packages = {
          zsh = let
            pkg = pkgs.zsh;
          in
            pkgs.symlinkJoin {
              inherit (pkg) name meta;
              paths = [ pkg ];
              nativeBuildInputs = [ pkgs.makeWrapper ];
              postBuild = ''
            wrapProgram $out/bin/zsh \
            --set ZDOTDIR ${base-config} \
            '';
            };
        };
      };
    };
}
