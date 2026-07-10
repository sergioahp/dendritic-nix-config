{ ... }: {
  flake.nixosModules.base = { pkgs, ... }: {
    users.users.admin = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJtxk8o6s+5hWqOEhZR8bG6knnKGhdZfd7EwBlGrBhmu desktop@lan -> nixos 2026-05-29"
      ];
    };
    programs.zsh.enable = true;
  };
}
