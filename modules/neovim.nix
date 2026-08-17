# Runtime dependencies for ~/.config/nvim.
#
# That Neovim config is deliberately NOT nix-managed: lazy.nvim fetches the Lua
# at runtime so plugins stay editable. Nix's job here is only to supply the
# external (non-Lua) tools each plugin shells out to, builds against, or needs
# as a language server. The mapping below was derived plugin-by-plugin from
# each plugin's README and cross-checked against the author's home-manager set.
#
# Two consumers, one list:
#   * `packages.neovim`  -- a wrapped nvim that carries every tool on its own
#     PATH, so `nix run <flake>#neovim` is a self-contained editor on any box.
#   * `neovim.runtimeDeps` -- the raw list, so `devShells.dev` (see
#     modules/shells/dev.nix) puts the same tools on the interactive PATH.
{ lib, ... }: {
  perSystem = { pkgs, config, ... }:
    let
      # pylsp with the mypy plugin, matching the home-manager python env.
      pyEnv = pkgs.python3.withPackages (ps: with ps; [
        python-lsp-server   # nvim-lspconfig: pylsp
        pylsp-mypy          # pylsp type-check plugin
      ]);

      neovim = pkgs.symlinkJoin {
        name = "neovim-with-tools";
        paths = [ pkgs.neovim ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        # --suffix, not --prefix: a project-local toolchain on the user's PATH
        # (e.g. a pinned rust-analyzer) still wins; these are the fallback.
        # --set-default NVIM_APPNAME: run under a separate app name so config
        # lives in ~/.config/<appName> and state in ~/.local/share/<appName>,
        # coexisting with a stock nvim. `default` so you can still override to
        # your main config with `NVIM_APPNAME=nvim nvim`.
        postBuild = ''
          wrapProgram $out/bin/nvim \
            --suffix PATH : ${lib.makeBinPath config.neovim.runtimeDeps} \
            --set-default NVIM_APPNAME ${config.neovim.appName}
        '';
        # The binary is `nvim`, not the derivation name -- so `nix run .#neovim`
        # (and anything reading meta.mainProgram) launches the editor.
        meta = pkgs.neovim.meta // { mainProgram = "nvim"; };
      };
    in
    {
      options.neovim.runtimeDeps = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          External tools required by the (non-nix-managed) ~/.config/nvim
          plugins. Wrapped onto `packages.neovim`'s PATH and reused by the dev
          shell.
        '';
      };

      options.neovim.appName = lib.mkOption {
        type = lib.types.str;
        default = "nvim-dend";
        description = ''
          NVIM_APPNAME baked (as an overridable default) into the wrapped nvim,
          so it reads ~/.config/''${appName} and stores state in
          ~/.local/share/''${appName} -- a side-by-side editor that never
          collides with a stock nvim. Point that config dir at your setup
          (e.g. symlink ~/.config/''${appName} -> ~/.config/nvim).
        '';
      };

      config = {
        neovim.runtimeDeps = with pkgs; [
          # --- plugin manager + git-backed plugins ---
          git                 # lazy.nvim bootstrap; gitsigns, vim-fugitive,
                              # vim-flog, cmp-git, telescope git_* pickers
          gh                  # octo.nvim + cmp-git (GitHub CLI)
          curl                # avante.nvim, minuet-ai, plenary.curl, cmp-git,
                              # nvim-treesitter parser download

          # --- telescope ---
          ripgrep             # live_grep + config/multigrep.lua (calls `rg`)
          fd                  # find_files

          # --- build toolchains invoked by plugin `build` steps ---
          gnumake             # telescope-fzf-native (`make`), LuaSnip
                              # (`make install_jsregexp`)
          gcc                 # C compiler: telescope-fzf-native, LuaSnip
                              # jsregexp, nvim-treesitter parser compilation
          tree-sitter         # nvim-treesitter (main): parser CLI, via a pkg
                              # manager rather than npm per its README
          cargo               # avante.nvim `make BUILD_FROM_SOURCE=true`
                              # (prebuilt libs are dynamically linked; on nix
                              # you build from source)

          # --- LSP servers (nvim-lspconfig `per_server`) ---
          lua-language-server # lua_ls
          pyEnv               # pylsp (+ pylsp-mypy)
          nil                 # nil_ls (Nix)
          rust-analyzer       # rust_analyzer
          clippy              # rust-analyzer check-on-save
          clang-tools         # clangd
          tinymist            # Typst LSP

          # --- typst filetype tooling ---
          typst               # compiler (after/ftplugin/typst.lua)
          typstyle            # formatter
          typst-live          # live preview

          # --- SQL (nvim-dbee) ---
          # Prebuilt Go backend binary, so the plugin's runtime `go build`
          # (require("dbee").install()) is never needed.
          vimPlugins.nvim-dbee
        ];

        packages.neovim = neovim;
      };
    };

  # Not wired here (needs extra inputs / per-project toolchains); add if wanted:
  #   * after/ftplugin/typst.lua starts `typst-languagetool-lsp` and reads
  #     $LANGUAGETOOL_JAR. Add the `typst-languagetool-nix` flake input, put
  #     inputs.typst-languagetool-nix.packages.${system}.lsp in runtimeDeps, and
  #     set LANGUAGETOOL_JAR (= that package's .languagetoolJar) in the shell.
  #   * lean.nvim needs a Lean toolchain (elan/lake), which is per-project.
}
