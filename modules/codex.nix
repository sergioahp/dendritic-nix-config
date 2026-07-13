{ ... }: {
  perSystem = { inputs', ... }: {
    # From llm-agents.nix rather than nixpkgs: new codex releases show up here
    # as soon as they're GA, instead of lagging the nixpkgs merge queue. As of
    # numtide/llm-agents.nix#6631 the package also builds the codex-code-mode-host
    # helper (codex spawns it for every shell command) into its own bin/, so no
    # wrapper is needed - codex finds the helper right beside itself.
    config.packages.codex = inputs'.llm-agents.packages.codex;
  };
}
