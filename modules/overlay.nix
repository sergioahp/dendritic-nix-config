{ inputs, ... }: {
  # Re-exports the wrapped cli packages as flake.overlays.default. easyOverlay
  # re-evaluates perSystem with the overlay's prev as pkgs, so the wraps (and the
  # merged aliases baked into zsh) rebuild against whatever nixpkgs the overlay is
  # applied to. Apply it wherever you want pkgs.zsh / pkgs.fzf / pkgs.claude-code
  # to resolve to the wrapped builds instead of the stock ones.
  imports = [ inputs.flake-parts.flakeModules.easyOverlay ];

  perSystem = { config, ... }: {
    overlayAttrs = {
      inherit (config.packages) zsh fzf claude-code;
    };
  };
}
