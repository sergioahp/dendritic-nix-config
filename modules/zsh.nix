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

      # Cursor shape follows vi mode: steady block in normal, steady bar in
      # insert. Nothing here touched cursor shape before, so it stayed the
      # terminal default (a bar) in every mode; Starship's ❯/❮ only ever
      # changed the prompt *symbol*. Requires a terminal that honours DECSCUSR
      # (xterm, kitty, alacritty, wezterm, foot, recent tmux).
      zle-keymap-select() {
        case $KEYMAP in
          vicmd)      print -n '\e[2 q' ;;  # normal: block
          main|viins) print -n '\e[6 q' ;;  # insert: bar
        esac
      }
      zle -N zle-keymap-select
      zle-line-init() { print -n '\e[6 q'; }  # each new prompt starts in insert
      zle -N zle-line-init

      preexec() {
        print -n '\e[6 q'  # reset to bar while a command runs
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
          cp = "cp -i";
          mv = "mv -i";
          rm = "rm -I";
        };
        packages = {
          zsh = let
            pkg = pkgs.zsh;
          in
            pkgs.symlinkJoin {
              inherit (pkg) name;
              # zsh is multi-output (out + man); the join is single-output, so
              # fold the man pages in and drop "man" from outputsToInstall,
              # otherwise home-manager's buildEnv trips on the missing output.
              meta = pkg.meta // { outputsToInstall = [ "out" ]; };
              # keep shellPath so NixOS still accepts the wrap as a login shell
              # (users.users.<n>.shell = pkgs.zsh); symlinkJoin drops passthru,
              # and $out/bin/zsh exists, so the base "/bin/zsh" still resolves.
              passthru = { inherit (pkg) shellPath; };
              paths = [ pkg pkg.man ];
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
