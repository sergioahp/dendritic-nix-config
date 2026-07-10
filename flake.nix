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
    # waiting out the nixpkgs merge queue. Follows the hm nixpkgs since that's
    # where claude-code actually gets installed.
    llm-agents.url = "github:numtide/llm-agents.nix";
    llm-agents.inputs.nixpkgs.follows = "nixpkgs-hm";
  };
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; }
    (inputs.import-tree ./modules);
}
