# Fill-space workspace client pills evidence

Date: 2026-07-13

Source revision: `fd2bdc2c27004d4bb07040ce04664fc2fa1df087`

Evidence harness revision: `75e3abf40c3182c350e48d7410915be3b3bd48b8`

Source branch: `feature/workspace-client-pills-fill`

Evidence branch: `vm-evidence-workspace-client-pills-fill`

## Result

- PASS: the active client pill continuously filled the otherwise unused center
  space between the unchanged left and right widget groups.
- PASS: with eight mapped clients, inactive icon-and-first-word pills stayed
  compact while the active workspace-colored pill absorbed the remaining
  width.
- PASS: the active pill moved between `Focus Left` and `Focus Right` while the
  other seven pills retained their compact treatment and order.
- PASS: the icon and title remain together as one centered content group even
  when the active pill becomes very wide.
- PASS: an inactive client updated live from compact `Waiting` to `Renamed`.
- PASS: rendered pill order exactly matched mapped workspace 2 client order
  from `hyprctl clients -j`.
- PASS: existing workspace, tray, Bluetooth, volume, network, battery, and time
  widgets retained their styling and passed the full regression suite.
- PASS: the bar stayed 25 pixels tall in all recorded states.
- PASS: the complete NixOS/Hyprland VM regression test finished successfully
  in 293.26 seconds.

## Fill evidence

`title-pill-fill-samples.txt` records four samples across 750 pixels of the
single-client active pill:

```text
output_width=1920
y=2
x=450,700,960,1200
colors=srgb(70,111,136),srgb(70,111,136),srgb(70,111,136),srgb(70,111,136)
```

All samples are the same non-background color. The VM asserts this equality,
proving that one active-pill background continuously covers that center span.
`11-title-short-bar.png` shows the full visual result: only the historical edge
container space remains outside the title region.

## Visual evidence

| File | Demonstrates |
| --- | --- |
| `11-title-short-bar.png` | One active client fills all available space between edge groups; icon and `hello` remain together at its center. |
| `15-focus-left-bar.png` | Eight clients fit across the available area, with a wider active `Focus Left` pill. |
| `16-focus-right-bar.png` | The expandable workspace-colored pill moves to `Focus Right`. |
| `18a-before-title-change-bar.png` | The inactive delayed-title client initially appears as `Waiting`. |
| `18b-after-title-change-bar.png` | The same inactive client updates in place to `Renamed`. |
| `15-focus-left.png` | Full-monitor context, including the unchanged non-title widget styling and tiled clients. |

The close-ups are independent crops; no screenshots were combined.

## Ordering evidence

`workspace-client-order.txt` records the filtered order returned by
`hyprctl clients -j`:

```text
0x585b39ecc9e0
0x585b3a13ac60
0x585b39cdaf40
0x585b3a0f2cb0
0x585b3b18bd60
0x585b3b294270
0x585b3a118570
0x585b3b083b20
```

`rendered-client-order.txt` records the eight consecutive GTK pill updates
after the inactive rename. Its addresses match this list exactly, including
active `Focus Right` in its original Hyprland position rather than moving the
active client to the front.

## Implementation exercised

- The outer bar is a horizontal GTK box containing the existing left group,
  an expanding client strip, and the existing right group.
- The strip receives every pixel left after the fixed side allocations.
- Only the active pill expands; inactive pills retain their natural compact
  widths.
- The fill branch groups icon and label inside the active pill's centered
  content widget. This avoids separating a start-slot icon from the title when
  the pill spans hundreds of pixels.
- The client model, live event coverage, order preservation, title compaction,
  address-based widget reuse, and icon caching are shared with the centered
  variant.

`bar-geometry.txt` records a 1920 by 25 layer surface for initial, title, tray,
menu, and tray-removal states.

## Verification commands

```sh
nix develop -c cargo fmt -- --check
nix develop -c cargo test
nix develop -c cargo clippy --workspace --all-targets
nix build .#checks.x86_64-linux.gtk-status-bar-vm -L \
  --out-link result-workspace-client-pills-fill_2026-07-13
```

The local and pinned release source suites each passed all 61 tests. Clippy
completed with only the repository's pre-existing warnings in `dbus.rs`,
`pw.rs`, and existing test module placement in `widgets.rs`.
