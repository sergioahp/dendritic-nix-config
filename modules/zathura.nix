{ lib, ... }: {
  perSystem = { config, pkgs, ... }:
    let
      colorLib = import ./theme/_color-lib.nix { inherit lib; };
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
        zathura.colors = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = ''
            Color-valued zathurarc options as hex strings, provided by the
            theme; formatted to rgba() and merged into zathura.options
          '';
        };
      };

      config.zathura.options = lib.mkMerge [
        {
          selection-clipboard = "clipboard";
          statusbar-home-tilde = true;
          window-title-basename = true;
          recolor-keephue = true;
          recolor = true;
        }
        (lib.mapAttrs (_: colorLib.toRgbaCss) config.zathura.colors)
      ];

      config.zathura.mappings = {
        i = "recolor";
      };

      config.packages.zathura =
        let
          pkg = pkgs.zathura;
          formatValue = v: if lib.isBool v then lib.boolToString v else toString v;
          # Renderer only covers set/map lines. Not yet handled (add when
          # needed): include directives, unmap, free-form extraConfig lines,
          # escaping of double quotes inside set values.
          zathurarc = pkgs.writeText "zathurarc" (lib.concatStringsSep "\n" (
            lib.mapAttrsToList (n: v: ''set ${n} "${formatValue v}"'') config.zathura.options
            ++ lib.mapAttrsToList (n: v: "map ${n} ${v}") config.zathura.mappings
          ) + "\n");
          config-dir = pkgs.linkFarm "zathura-config" [
            { name = "zathurarc"; path = zathurarc; }
          ];
        in
        pkgs.symlinkJoin {
          inherit (pkg) name meta;
          paths = [ pkg ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/zathura \
              --add-flags "--config-dir ${config-dir}"
          '';
        };
    };
}
