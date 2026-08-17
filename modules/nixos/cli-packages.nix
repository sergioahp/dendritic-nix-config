{ self, ... }: {
  # Put the wrapped cli collection on every host: the overlay makes pkgs.zsh /
  # pkgs.fzf resolve to the wrapped builds, so the login shell
  # (users.users.admin.shell = pkgs.zsh) and anything launched from the system
  # PATH - including terminals opened via xdg-open - get the correct ones.
  # claude-code stays out of the bare system config; it lives on the home layer
  # instead (sourced from llm-agents, on the faster nixpkgs-hm cadence).
  #
  # Deliberately short, and meant to stay that way: the system tier only owes a
  # user enough to log in, read a file and fix the config that is broken. The
  # actual toolchain arrives per-user from home-manager, where it can differ
  # between admin and personal and be rolled back without a reboot. Anything
  # added here is added to every host and every user at once, so the bar is
  # "would I miss this while repairing a system that will not switch".
  flake.nixosModules.base = { pkgs, ... }: {
    nixpkgs.overlays = [ self.overlays.default ];
    environment.systemPackages = [
      pkgs.zsh
      pkgs.fzf
      pkgs.tmux
      pkgs.btop
      # Bare nvim, no plugins: the editor of last resort, for the case where
      # home-manager is exactly what is broken. The configured one is a home
      # package.
      pkgs.neovim
      # git is not optional on a flake host -- nix cannot read this repo
      # without it, so a host that loses git cannot rebuild itself.
      pkgs.git
      pkgs.wget
      pkgs.tree
      # No kitty.terminfo here, though ssh sessions from the desktop do arrive
      # with an unknown TERM=xterm-kitty. terminfo is an output of the kitty
      # derivation, kitty is not in the binary cache at this nixpkgs revision,
      # and building it from source fails its own test suite. Use `kitten ssh`
      # from the desktop instead: it ships the terminfo over the connection, so
      # nothing has to be installed on the far end at all.
    ];
  };
}
