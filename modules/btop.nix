{ ... }: {
  perSystem = { pkgs, ... }:
    let
      pkg = pkgs.btop;
      # Mirrors the programs.btop settings from ~/.config/home-manager. btop reads
      # the file passed via -c; it can't write runtime changes back to a store
      # path, which is exactly what we want from a declaratively-owned config.
      btop-conf = pkgs.writeText "btop.conf" ''
        theme_background = false
        vim_keys = true
        update_ms = 100
      '';
    in {
      packages.btop = pkgs.symlinkJoin {
        inherit (pkg) name meta;
        paths = [ pkg ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/btop --add-flags "--config ${btop-conf}"
        '';
      };
    };
}
