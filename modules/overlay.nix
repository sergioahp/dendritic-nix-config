{ inputs, ... }: {
  # Re-exports the wrapped cli packages as flake.overlays.default. easyOverlay
  # re-evaluates perSystem with the overlay's prev as pkgs, so the wraps (and the
  # merged aliases baked into zsh) rebuild against whatever nixpkgs the overlay is
  # applied to. Apply it wherever you want pkgs.zsh / pkgs.fzf / pkgs.claude-code
  # to resolve to the wrapped builds instead of the stock ones.
  imports = [ inputs.flake-parts.flakeModules.easyOverlay ];

  perSystem = { config, ... }: {
    # These names shadow the base nixpkgs attributes system-wide wherever the
    # overlay is applied. zsh composes with NixOS programs.zsh fine (the wrap
    # forces ZDOTDIR to the repo zshrc; /etc/zshenv and /etc/zshrc still load
    # first), but if system zsh completions / vendor setup ever misbehave, the
    # escape hatch is to expose the wrap under its own attr (e.g. zsh-cli)
    # instead of shadowing zsh, and install that name explicitly.
    overlayAttrs = {
      inherit (config.packages) zsh fzf claude-code tmux btop;
    };
  };
}
