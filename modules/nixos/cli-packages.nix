{ self, ... }: {
  # Put the wrapped cli collection on every host: the overlay makes pkgs.zsh /
  # pkgs.fzf / pkgs.claude-code resolve to the wrapped builds, so the login shell
  # (users.users.admin.shell = pkgs.zsh) and anything launched from the system
  # PATH - including terminals opened via xdg-open - get the correct ones.
  flake.nixosModules.base = { pkgs, ... }: {
    nixpkgs.overlays = [ self.overlays.default ];
    nixpkgs.config.allowUnfree = true; # claude-code
    environment.systemPackages = [ pkgs.zsh pkgs.fzf pkgs.claude-code ];
  };
}
