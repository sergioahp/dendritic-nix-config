# Theme layer and zathura runtime theme switching

Date: 2026-07-16

This documents the theming rework brought into this repo, the design
conversation behind it, the zathura render race found while implementing
runtime switching, and where this is headed next.

## Motivation

The home-manager setup themed apps through a single nix-rice palette module
(colors.nix) with per-app converters, and each app module mapped palette
entries to its options inline. It worked but was messy: raw and role names
mixed in one palette, opacity constants repeated at every usage site, a
nix-rice dependency for what is essentially hex parsing plus three output
formats, and nsxiv's config builder carried real bugs (see below).

This repo's pattern is different: programs are wrapped so they carry their
own config and need no external files (yazi, fzf, ...). The theming rework
follows that pattern. First targets: zathura and nsxiv (dunst next; kitty
later, it has more surface in home-manager).

## Design

Layering, as settled in discussion:

- Canonical palette: named colors as hex strings. Names describe the color's
  appearance only (gunmetal, midnight, periwinkle, coral), never a role or
  eventual use. Anything like bg, fg, highlight, terminal-black, urgent or
  claude-warm is banned at this layer; those are roles and they leak app
  knowledge into the palette.
- Theme-owned mapping: each theme maps its palette into per-app views, and
  assigns alphas there (the same color is commonly used at several opacities
  per role). The view is deliberately shaped like what the app expects: an
  attrset keyed by the app's own option names, values still hex strings.
- App-owned plumbing: the app module declares the option where a view plugs
  in and owns formatting (hex to rgba() for zathura, hex to #rrggbb for X
  resources) and placement into the actual config format.
- Vendored color utils instead of nix-rice: modules/theme/_color-lib.nix.
  Canonical representation is a hex string everywhere ("#rgb", "#rgba",
  "#rrggbb", "#rrggbbaa"); transforms return hex so they compose. Provides
  parse, withAlpha, scaleAlpha, mix, darken/lighten/saturate/desaturate via
  a proper HSL round trip, an onHsl escape hatch, and formatters toRgbHex,
  toRgbaHex, toRgbaCss, toRgbCss. The underscore prefix keeps import-tree
  from loading it as a flake-parts module.

Multiple output files per app was a design goal from the start: pre-render
one complete config per theme at build time so a runtime theme change never
evaluates nix and never leaves half-applied state.

## What is implemented

- modules/theme/palette.nix: theme.colors (canonical palette of the default
  theme) and theme.default (name used when no runtime choice exists).
- modules/theme/tokyonight.nix: dark default theme. Exports theme.colors
  plus views zathura.themes.tokyonight and nsxiv.colors.
- modules/theme/pastel.nix: light theme, near-white surfaces with little
  transparency (95% opacity backgrounds), soft accents. Non-default themes
  keep their palette let-bound and only export per-app views.
- modules/zathura.nix:
  - zathura.options / zathura.mappings: shared zathurarc content. The
    renderer covers set/map lines only; include directives, unmap, free-form
    extraConfig and quote escaping are marked in a comment as not yet
    handled, to be added when someone needs them.
  - zathura.themes.<name>: color views. An eval-time assertion enforces that
    every theme defines the same key set, because the runtime switch replays
    a full set of options; differing key sets would leave stale values when
    switching (zathura config is incremental by nature).
  - packages.zathura-themes: linkFarm with one pre-rendered config dir per
    theme: <store>/zathura-themes/<name>/zathurarc.
  - packages.zathura: launcher resolving
    ${XDG_STATE_HOME:-~/.local/state}/theme/zathura first, falling back to
    the default theme's store dir. No home-manager involvement anywhere.
  - packages.theme-switch: flips the state symlink (new instances), then
    calls org.pwmt.zathura.SourceConfigFromDirectory over the session bus on
    every org.pwmt.zathura.PID-* name (running instances). Whole swap is
    about 70ms; no nix in the hot path.
- modules/nsxiv.nix: nsxiv has no config file, so colors are compiled in via
  the nixpkgs conf override, as X resource fallbacks. That keeps them
  runtime-overridable through xrdb later (nsxiv is X11/XWayland). Ported
  from the home-manager builder with two bugs fixed: win_fg was bound to the
  X resource "Nsxiv.window.background" instead of ".foreground" (an xrdb
  entry would have set fg = bg), and thumb_sizes contained 6 where upstream
  has 96 (a 6 pixel thumbnail size in the cycle).
- modules/overlay.nix exports zathura, nsxiv and theme-switch; yazi's
  openers now use the wrapped viewers.

Verified on the host with live instances and pixel-checked screenshots:
tokyonight and pastel both render exactly the palette values, new instances
pick up the state symlink, running instances follow switches both ways.

## The zathura render race

Symptom: after theme-switch, one instance updated its statusbar and UI
colors but kept the previous theme's page rendering. Reproducible with a
slowly rendering document; fast documents always switched cleanly.
Individual `set recolor-darkcolor ...` commands over D-Bus always worked.
Running the exact same source call a second time always fixed the stale
instance.

Root cause, from the zathura 2026.05.20 sources:

- zathura/render.c, zathura_render_request: "only add a new job if there are
  no active ones left". A render request arriving while a job for that page
  is already in flight is silently dropped, and nothing re-queues it when
  the in-flight job lands.
- zathura/config.c, cb_color_change: every color-valued setting triggers
  zathura_document_widget_render_all. Sourcing a config file therefore fires
  one render_all per color option, in file order.
- Our zathurarc is written alphabetically, so highlight-active-color hits
  cb_color_change before recolor-darkcolor/recolor-lightcolor are parsed. A
  page that starts rendering on that first render_all grabs the OLD recolor
  colors; every later request (issued after the new colors land) is dropped
  against the in-flight job; the stale surface is installed and stays.

Whether an instance gets stuck is a pure race between page render time and
config parse time, which is why only slow pages lost it.

Workaround implemented in theme-switch: source every instance twice with a
0.3s pause. On the second pass the recolor colors are already correct when
the first render job starts, so its result is right even if later requests
are dropped. Stress-tested 4 rounds in both directions with 3 live
instances, zero failures.

Upstream angle: this is arguably a zathura bug. A proper fix would be to
mark a pending re-render when a request is dropped against an active job and
re-queue on job completion, or to have config sourcing coalesce into a
single render_all after parsing. Candidate for a patch or fork if the 0.3s
double pass ever bothers us.

## Future intent

- dunst: same view pattern (theme sets dunst-shaped colors, alphas at the
  view level); runtime swap via dunstctl reload pointed at a pre-rendered
  dunstrc per theme (we run the sergioahp/dunst fork, so reload behavior is
  under our control).
- nsxiv runtime: emit a per-theme Xresources fragment next to the zathura
  dirs and xrdb -merge it in theme-switch; the compiled colors are only
  fallbacks, so one binary serves all themes.
- Generalize theme-switch: today it is zathura-only. When a second app joins
  the runtime swap, converge on one bundle layout
  (<themes>/<name>/<app>/<file>) and one state pointer
  (~/.local/state/theme/current) that flips every app at once.
- Rofi theme menu on a keybind: being tested unsupervised by codex in the
  theme-swap-testing worktree, inside the desktop-graphical VM, with video
  evidence as the exit criterion (see the untracked CODEX-INSTRUCTIONS.md in
  that worktree).
- A future home-manager module may manage the state symlink and keybinds on
  real machines, but the packages must keep working without it; that
  boundary is deliberate.
- Semantic role layer: if more apps join and the per-theme views start
  repeating role decisions (panel bg at 38%, accent, urgent), introduce a
  thin shared role mapping between palette and views. Not needed at two
  apps; revisit at dunst time.
