{ lib, ... }: {
  perSystem = { config, pkgs, ... }:
    let
      colorLib = import ./theme/_color-lib.nix { inherit lib; };
      formatValue = v: if lib.isBool v then lib.boolToString v else toString v;
      # Renderer only covers set/map lines. Not yet handled (add when
      # needed): include directives, unmap, free-form extraConfig lines,
      # escaping of double quotes inside set values.
      renderRc = { options, mappings }: colors: lib.concatStringsSep "\n" (
        lib.mapAttrsToList (n: v: ''set ${n} "${formatValue v}"'')
          (options // lib.mapAttrs (_: colorLib.toRgbaCss) colors)
        ++ lib.mapAttrsToList (n: v: "map ${n} ${v}") mappings
      ) + "\n";
    in
    {
      options = {
        zathura.options = lib.mkOption {
          type = with lib.types; attrsOf (oneOf [ str bool int float ]);
          default = { };
          description = "Rendered as `set` lines in zathurarc; see zathurarc(5)";
        };
        zathura.mappings = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = ''
            Rendered as `map` lines in zathurarc; prefix the key with
            "[mode] " for mode-specific mappings
          '';
        };
        zathura.themes = lib.mkOption {
          type = with lib.types; attrsOf (attrsOf str);
          default = { };
          description = ''
            Per theme name: color-valued zathurarc options as hex strings,
            provided by the theme modules; formatted to rgba() and merged
            with zathura.options into one zathurarc per theme. Every theme
            must define the same key set so the runtime switch always
            replays a full set of values.
          '';
        };
      };

      config.zathura.options = {
        selection-clipboard = "clipboard";
        statusbar-home-tilde = true;
        window-title-basename = true;
        recolor-keephue = true;
        recolor = true;
      };

      config.zathura.mappings = {
        i = "recolor";
      };

      config.packages = {
        zathura =
          let
            pkg = pkgs.zathura;
            launcher = pkgs.writeShellScriptBin "zathura" ''
              dir="''${XDG_STATE_HOME:-$HOME/.local/state}/theme/zathura"
              [ -e "$dir/zathurarc" ] || dir="${config.packages.zathura-themes}/${config.theme.default}"
              exec "${pkg}/bin/zathura" --config-dir "$dir" "$@"
            '';
          in
          pkgs.symlinkJoin {
            inherit (pkg) name meta;
            # launcher first: its bin/zathura wins the collision with pkg's
            paths = [ launcher pkg ];
          };

        # one config dir per theme, all pre-rendered so the runtime switch
        # never has to evaluate any nix
        zathura-themes =
          let
            themeNames = lib.attrNames config.zathura.themes;
            keySets = lib.mapAttrsToList (_: v: lib.attrNames v) config.zathura.themes;
            consistent = lib.all (ks: ks == lib.head keySets) keySets;
          in
          assert lib.assertMsg (config.zathura.themes ? ${config.theme.default})
            "zathura.themes is missing the default theme ${config.theme.default}";
          assert lib.assertMsg consistent
            "all zathura.themes must define the same color keys, otherwise a runtime switch leaves stale values behind (themes: ${toString themeNames})";
          pkgs.linkFarm "zathura-themes" (lib.mapAttrsToList (name: colors: {
            inherit name;
            path = pkgs.writeTextDir "zathurarc"
              (renderRc { inherit (config.zathura) options mappings; } colors);
          }) config.zathura.themes);

        # Instant theme swap, no home-manager and no nix in the hot path:
        # point the state symlink at the chosen pre-rendered config dir (new
        # instances pick it up via the launcher) and have every running
        # instance source that dir over D-Bus. Each zathurarc carries the
        # full option set, which sidesteps zathura's incremental-config
        # problem.
        theme-switch = pkgs.writeShellApplication {
          name = "theme-switch";
          runtimeInputs = with pkgs; [ systemd coreutils gnugrep gawk ];
          text = ''
            themes="${config.packages.zathura-themes}"
            if [ $# -ne 1 ] || [ ! -e "$themes/$1" ]; then
              echo "usage: theme-switch <theme>" >&2
              echo "available themes:" >&2
              ls "$themes" >&2
              exit 1
            fi

            theme="$1"
            state="''${XDG_STATE_HOME:-$HOME/.local/state}/theme"
            mkdir -p "$state"
            ln -sfT "$themes/$theme" "$state/zathura"

            source_all() {
              busctl --user list --acquired --no-legend 2>/dev/null \
                | awk '{ print $1 }' \
                | { grep '^org\.pwmt\.zathura\.PID-' || true; } \
                | while read -r service; do
                    busctl --user call "$service" /org/pwmt/zathura \
                      org.pwmt.zathura SourceConfigFromDirectory s "$themes/$theme" \
                      > /dev/null \
                      || echo "warning: $service did not take the switch" >&2
                  done
            }

            source_all
            # zathura drops render requests while a job is in flight
            # (render.c: "only add a new job if there are no active ones
            # left"). Sourcing a config re-renders once per color option, so
            # a page that renders slowly starts its job before the recolor
            # colors are parsed and keeps the pre-switch look. A second pass
            # after those jobs settle re-sources with everything in place.
            sleep 0.3
            source_all
          '';
        };
      };
    };
}
