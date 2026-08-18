{ lib, ... }:

{
  perSystem = { pkgs, ... } :
    let
      # One definition, two consumers below: the wrapper, so a bare `fzf` from
      # anywhere (a script, yazi, a shell that is not ours) still looks right,
      # and the zsh exports, so fzf's own widgets can compose these with the
      # per-widget options they add.
      defaultOpts = [
        "--layout=reverse"
        "--info=inline"
        "--height=40%"
        "--bind='ctrl-/:toggle-preview'"
        "--multi"
      ];

      # Per-widget options, mirroring the set in ~/.config/home-manager. These
      # can only come from the shell: they are read by the zsh functions that
      # `fzf --zsh` defines, not by the fzf binary, so no amount of wrapping
      # can supply them.
      widgetOpts = {
        # ctrl-R feeds fzf "<event number>\t<command>" records, and without
        # this the event number is displayed in front of every entry.
        FZF_CTRL_R_OPTS = [
          "--with-nth 2.."
          # wl-copy resolved from PATH rather than pinned to a store path,
          # unlike bat and eza below. This binding only means anything inside a
          # wayland session, and pinning it would pull wl-clipboard into the
          # closure of a cli tool that is also used over ssh; unresolved, the
          # binding is a silent no-op instead.
          "--bind='ctrl-y:execute-silent(echo -n {2..} | wl-copy)+abort'"
        ];
        FZF_CTRL_T_OPTS = [
          "--walker-skip=.git,node_modules,target"
          "--preview='${pkgs.bat}/bin/bat --style=plain --color=always --line-range :500 {}'"
          "--bind='ctrl-/:change-preview-window(down|hidden|)'"
        ];
        FZF_ALT_C_OPTS = [
          "--preview='${pkgs.eza}/bin/eza -T --color=always {} | head -200'"
        ];
      };

      opts = lib.concatStringsSep " ";
      export = name: value: "export ${name}=${lib.escapeShellArg value}";

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
          # Defaults for whoever did not ask for anything, which still leaves
          # them overridable per invocation without editing nix stuff -- either
          # FZF_DEFAULT_OPTS in the environment or FZF_DEFAULT_OPTS_FILE, both
          # of which fzf reads on its own.
          #
          # set-default and not set, which is the whole point: fzf's shell
          # widgets do not *add* to FZF_DEFAULT_OPTS, they build the entire
          # value themselves (base opts + the widget's own) and hand it to this
          # binary. A plain --set overwrote that, so every widget silently lost
          # the options that make it work -- ctrl-R lost --read0 and rendered
          # the whole NUL-separated history as one entry, plus --scheme=history,
          # the nth field and toggle-sort. Nothing about it looked right, and
          # nothing about the wrapper looked wrong either.
          wrapProgram $out/bin/${mainProgram} \
            --set-default FZF_DEFAULT_OPTS "${opts defaultOpts}" \
        '';
      };

      # The other half. The widgets compose their options from what the *shell*
      # exports, so this is the only place the per-widget sets can be delivered
      # at all, and FZF_DEFAULT_OPTS has to be here too or the widgets compose
      # without it and come out looking nothing like a bare fzf. Lands after
      # `source <(fzf --zsh)` in the zshrc, which is fine: the widgets read
      # these when they run, not when they are defined.
      zsh.initExtra = lib.concatLines (
        [ (export "FZF_DEFAULT_OPTS" (opts defaultOpts)) ]
        ++ lib.mapAttrsToList (name: value: export name (opts value)) widgetOpts
      );
    };
}
