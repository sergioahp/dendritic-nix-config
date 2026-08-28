{ ... }: {
  perSystem = { pkgs, ... }:
    let
      pkg = pkgs.tmux;
      tmux-conf = pkgs.writeText "tmux.conf" /* tmux */ ''

        # Get true color support. Proper solution would be to install the
        # terminal's terminfo
        set -g default-terminal "tmux-256color"
        set -as terminal-features ",*:RGB"

        # Same as above, get extended keys support. Same terminfo
        # situation.
        set -s extended-keys on
        set -as terminal-features ",*:extkeys"

        set -s escape-time 0
        unbind C-b
        set -g prefix C-a
        bind C-a send-prefix
        set -g mode-keys vi
        set -g status-keys vi
        set -g history-limit 5000
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R
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
