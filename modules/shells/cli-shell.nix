{ ... }: {
  perSystem = { pkgs, self', ...}: {
    devShells.cli-only = pkgs.mkShell {
      packages = [
        self'.packages.fzf
      ];
      env = {
        # TODO: this will be used on homemanager too, remember later to abstract
        EDITOR = "${pkgs.neovim}/bin/nvim";
        MANPAGER = "${pkgs.neovim}/bin/nvim +Man!=";
      };
    };
  };
}
