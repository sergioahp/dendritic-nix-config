{ ... }: {
  perSystem = { pkgs, ... }:
    let
      pkg = pkgs.tmux;
      # Mirrors the programs.tmux settings from ~/.config/home-manager, baked
      # into the package via -f so dev / nixos / home all get the same tmux with
      # no dotfiles to sync.
      tmux-conf = pkgs.writeText "tmux.conf" ''
        set -g default-terminal "tmux-256color"
        set -s escape-time 0
        unbind C-b
        set -g prefix C-a
        bind C-a send-prefix
        set -g mode-keys vi
        set -g status-keys vi
        set -g history-limit 5000
      '';
    in {
      packages.tmux = pkgs.symlinkJoin {
        inherit (pkg) name;
        # tmux is multi-output (out + man); the join is single-output, so fold the
        # man pages in and drop "man" from outputsToInstall to match.
        meta = pkg.meta // { outputsToInstall = [ "out" ]; };
        paths = [ pkg pkg.man ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/tmux --add-flags "-f ${tmux-conf}"
        '';
      };
    };
}
