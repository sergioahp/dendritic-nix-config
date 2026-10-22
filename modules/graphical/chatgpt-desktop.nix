{ ... }: {
  perSystem = { pkgs, inputs', ... }:
    let
      # Upstream attr is "chatgpt", not "codex": OpenAI ships one desktop app
      # for both. nixpkgs also has a "chatgpt" attr, so overlay.nix shadows it
      # the same way it does claude-code/claude-desktop/codex/opencode.
      chatgpt-pkg = inputs'.llm-agents.packages.chatgpt;
    in {
      config.packages.chatgpt = chatgpt-pkg.override {
        # Hyprland keyring fix, same as claude-desktop.nix; gnome-keyring
        # itself is enabled in secret-service.nix.
        commandLineArgs = "\${HYPRLAND_INSTANCE_SIGNATURE:+--password-store=gnome-libsecret}";
      };
    };

  # GUI app, graphical tier only, same as claude-desktop.
  flake.nixosModules.graphical = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.chatgpt ];
  };
}
