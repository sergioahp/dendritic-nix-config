{ lib, ... }: {
  perSystem = { config, pkgs, ... }: {
    options = {
      yazi.settings = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Passed as a lua table to the plugin's setup function";
      };
      yazi.keymap = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };
    };
    config.zsh.initExtra = /* zsh */ ''
      function y() {
        local tmp
        tmp="$(mktemp -t yazi-cwd.XXXXX)"
        ${pkgs.yazi}/bin/yazi "$@" --cwd-file="$tmp"
        if cwd="$(<"$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }
    '';
    config.yazi.settings = {
      # video thumbnails are slow to generate and rarely worth it; skip them
      plugin.prepend_preloaders = [
        { mime = "video/*"; run = "noop"; }
      ];
      opener = {
        images = [
          {
            run = ''${config.packages.nsxiv}/bin/nsxiv "$@"'';
            orphan = true;
            desc = "nsxiv (image viewer)";
          }
        ];
        docs = [
          {
            run = ''${config.packages.zathura}/bin/zathura "$@"'';
            orphan = true;
            desc = "zathura (document viewer)";
          }
        ];
        video = [
          {
            run = ''${pkgs.mpv}/bin/mpv --fs "$@"'';
            orphan = true;
            desc = "mpv (video player)";
          }
        ];
        edit = [
          {
            run = ''${pkgs.neovim}/bin/nvim "$@"'';
            block = true;
            desc = "Neovim (text editor)";
          }
        ];
      };
      open.prepend_rules = [
        { mime = "image/vnd.djvu"; use = "docs"; }
        { mime = "image/x-djvu"; use = "docs"; }
        { url = "*.djvu"; use = "docs"; }
        { url = "*.djv"; use = "docs"; }
        { url = "*.pdf"; use = "docs"; }
        { url = "*.epub"; use = "docs"; }
        { mime = "video/*"; use = "video"; }
        { mime = "text/*"; use = "edit"; }
        { mime = "image/*"; use = "images"; }
      ];
    };
    config.yazi.keymap = {
      mgr.prepend_keymap = [
        {
          on = "<C-d>";
          run = ''shell -- ${pkgs.dragon-drop}/bin/dragon-drop "$@";'';
          desc = "Dragon drop";
        }
        {
          on = "<C-o>";
          run = "back";
          desc = "Dir history back";
        }
        {
          on = "<C-i>";
          run = "forward";
          desc = "Dir history forward";
        }
      ];
    };
    config.packages = {
      yazi = let
        pkg = pkgs.yazi;
        format = pkgs.formats.toml {};
        yazi-toml = format.generate "yazi.toml" config.yazi.settings;
        keymap-toml = format.generate "keymap.toml" config.yazi.keymap;
        yazi-config-home = pkgs.linkFarm "yazi-config-home" [
          {
            name = "yazi.toml";
            path = yazi-toml;
          }
          {
            name = "keymap.toml";
            path = keymap-toml;
          }
        ];
      in
        pkgs.symlinkJoin {
          inherit (pkg) name meta;
          nativeBuildInputs = [ pkgs.makeWrapper ];
          paths = [ pkg ];
          postBuild = ''
            wrapProgram $out/bin/yazi \
              --set YAZI_CONFIG_HOME ${yazi-config-home}
          '';
        };
    };
  };
}
