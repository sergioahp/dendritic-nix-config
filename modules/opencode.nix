{ ... }: {
  perSystem = { inputs', ... }: {
    # From llm-agents.nix so new releases show up as soon as they're GA instead
    # of lagging the nixpkgs merge queue. It is also what the pre-dendritic
    # ~/.config/home-manager was reaching for a separate "bleeding" nixpkgs
    # input to get; that input has no equivalent here and does not need one.
    #
    # No wrapper. claude-code gets one to hand it a bash with our aliases, and
    # opencode has no equivalent knob worth setting from nix -- its provider
    # credentials come from the environment (OPENROUTER_API_KEY and friends,
    # which modules/auth-common exports) or from its own `opencode auth login`
    # store, and everything else is per-project config.
    config.packages.opencode = inputs'.llm-agents.packages.opencode;
  };
}
