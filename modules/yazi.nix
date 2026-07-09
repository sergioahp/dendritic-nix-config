{ ... }: {
  perSystem = { pkgs, ... }: {
    zsh.initExtra = /* zsh */ ''
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
  };
}
