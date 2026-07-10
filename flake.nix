{
  description = "A set of cli tools for daily use";
  
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    import-tree.url = "github:denful/import-tree";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixpkgs-hm.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-hm";

    # claude-code (and other agents) land here as soon as they're GA, without
    # waiting out the nixpkgs merge queue. Deliberately NOT following our
    # nixpkgs: llm-agents' CI builds against its own pinned nixpkgs and pushes
    # to cache.numtide.com, so we pull those pre-built binaries only when we
    # evaluate the same combination. `.follows` would rebuild everything
    # against nixpkgs-hm and miss the cache (costs a second nixpkgs eval).
    # The substituter is wired in at the NixOS level in
    # modules/nixos/llm-agents-cache.nix.
    llm-agents.url = "github:numtide/llm-agents.nix";
  };
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; }
    (inputs.import-tree ./modules);
}
