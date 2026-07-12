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

    # VM-evidence pin: the exact gtk-status-bar rev under test in
    # modules/checks/gtk-status-bar-vm.nix. Pinned to a full rev so the
    # evidence gathered from the VM is tied to one commit, not a moving branch.
    gtk-status-bar.url = "github:sergioahp/gtk-status-bar/bddef2aafb97974bc01227bfeaef5e2b937342bd";

    # TEMPORARY: prebuilt codex-code-mode-host helper that codex >= 0.144.0
    # spawns for every shell command; llm-agents' codex package doesn't ship it
    # yet (numtide/llm-agents.nix#6631). The version in the URL must match
    # llm-agents' codex (asserted in modules/codex.nix). Drop this input and
    # the module's shim once #6631 lands. flake=false: it's a source tarball.
    codex-code-mode-host-bin = {
      url = "https://github.com/openai/codex/releases/download/rust-v0.144.1/codex-code-mode-host-x86_64-unknown-linux-musl.tar.gz";
      flake = false;
    };
  };
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; }
    (inputs.import-tree ./modules);
}
