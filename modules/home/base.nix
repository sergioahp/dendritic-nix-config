{ ... }: {
  # Shared home config for every host. Any module may append to this same
  # attribute and it all merges, exactly like flake.nixosModules.base does for
  # the system layer. Host-specific bits (screen, mouse, chrome gpu accel, ...)
  # will land in per-host modules that get imported alongside this one.
  # username/homeDirectory are not here: this module is shared by every user,
  # and hosts.nix supplies them per generation.
  flake.modules.homeManager.base = { pkgs, ... }: {
    home.stateVersion = "25.11";
    # pkgs is overlaid in the host files, so these are the wrapped builds. On the
    # user PATH they cover xdg-open / desktop-launched processes in the session.
    home.packages = [ pkgs.zsh pkgs.fzf pkgs.claude-code pkgs.codex pkgs.tmux pkgs.btop ];
  };
}
