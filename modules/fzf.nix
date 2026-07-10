{ ... }:

{
  perSystem = { pkgs, ... } :
    let
      fzf-config = ''
      --layout=reverse
      --info=inline
      --height=40%
      --bind='ctrl-/:toggle-preview'
      --multi
      '';
      pkg = pkgs.fzf;
      mainProgram = pkg.meta.mainProgram or pkg.name;

    in {
      packages.fzf = pkgs.symlinkJoin {
        inherit (pkg) name;
        # fzf is multi-output (out + man); the join is single-output, so fold
        # the man pages in and drop "man" from outputsToInstall, otherwise
        # home-manager's buildEnv trips on the missing output.
        meta = pkg.meta // { outputsToInstall = [ "out" ]; };
        paths = [ pkg pkg.man ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          # Pass default opts, but allow user to override them without editing
          # nix stuff (comfy for hot-reloading) via a file, try not to conflict
          # with pre-existing fzf config files.
          wrapProgram $out/bin/${mainProgram} \
            --set FZF_DEFAULT_OPTS "${fzf-config}" \
        '';
      };
    };
}
