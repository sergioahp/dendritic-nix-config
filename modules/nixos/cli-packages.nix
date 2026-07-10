{ self, ... }: {
  # Put the wrapped cli collection on every host: the overlay makes pkgs.zsh /
  # pkgs.fzf resolve to the wrapped builds, so the login shell
  # (users.users.admin.shell = pkgs.zsh) and anything launched from the system
  # PATH - including terminals opened via xdg-open - get the correct ones.
  # claude-code stays out of the bare system config; it lives on the home layer
  # instead (sourced from llm-agents, on the faster nixpkgs-hm cadence).
  flake.nixosModules.base = { pkgs, ... }: {
    nixpkgs.overlays = [ self.overlays.default ];
    environment.systemPackages = [ pkgs.zsh pkgs.fzf pkgs.tmux pkgs.btop ];
  };
}
