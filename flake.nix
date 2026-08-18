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
    # modules/nixos/llm-agents-cache.nix. As of numtide/llm-agents.nix#6631
    # their codex package also builds the codex-code-mode-host helper into its
    # own bin/, so the prebuilt-binary shim it used to need is gone.
    llm-agents.url = "github:numtide/llm-agents.nix";

    # Nothing in the public tree references this. It is used only by
    # modules/auth-common, the private submodule holding the day-to-day API
    # tokens, and a submodule cannot declare a flake input of its own -- so the
    # input has to be out here whether or not the submodule is checked out.
    # Following our nixpkgs: sops-nix is build tooling, not upstream binaries
    # worth a second nixpkgs eval to hit a cache with.
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; }
    (inputs.import-tree ./modules);
}
