{ ... }: {
  perSystem = { inputs', ... }: {
    # oh-my-pi, upstream attr is "omp". nixpkgs has its own "omp" too, shadowed
    # in overlay.nix like the other llm-agents.nix picks.
    config.packages.omp = inputs'.llm-agents.packages.omp;
  };
}
