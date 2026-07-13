# Centered workspace client pills evidence

Date: 2026-07-13

Source revision: `0d9f2b4f0eab35ac34ce8a0fd4005fe2efceb435`

Evidence harness revision: `28877b078c0fef35c5b50bdc1ad59f0123896024`

Source branch: `feature/workspace-client-pills-center`

Evidence branch: `vm-evidence-workspace-client-pills-center`

## Result

- PASS: all eight mapped clients on the current workspace appeared as ordered
  icon-and-title pills.
- PASS: the focused client used the wider workspace-colored pill while every
  inactive client used its compact first-word title and neutral pill.
- PASS: focus moved between the two tiled clients without moving the complete
  strip away from the monitor center.
- PASS: an inactive client changed its title from `Waiting client` to
  `Renamed client`; the bar updated its compact label from `Waiting` to
  `Renamed` without focusing that client.
- PASS: rendered pill order exactly matched the order returned by
  `hyprctl clients -j` for mapped workspace 2 clients.
- PASS: the bar stayed 25 pixels tall in all recorded states.
- PASS: the complete NixOS/Hyprland VM regression test finished successfully
  in 293.22 seconds.

## Visual evidence

| File | Demonstrates |
| --- | --- |
| `15-focus-left-bar.png` | The wider blue pill identifies `Focus Left`; the neighboring inactive `Focus` pill is compact. |
| `16-focus-right.png` | Focus changed to the right tiled client and the wider blue pill moved to `Focus Right`. |
| `18a-before-title-change-bar.png` | The inactive delayed-title client initially appears as compact `Waiting`. |
| `18b-after-title-change-bar.png` | The same inactive client updates in place to compact `Renamed`. |
| `15-focus-left.png` | Full-monitor context with the current workspace's complete client strip. |

The close-ups are independent crops; no screenshots were combined.

## Ordering evidence

`workspace-client-order.txt` records the filtered order returned by
`hyprctl clients -j`:

```text
0x57c07edca530
0x57c07ebdd140
0x57c07ec51e80
0x57c07fc69630
0x57c07fdc32d0
0x57c07fc75300
0x57c07ecb0460
0x57c07fc14030
```

`rendered-client-order.txt` records the corresponding consecutive GTK pill
updates. Its addresses occur in exactly the same sequence. The accompanying
titles make the visual order explicit: `hello`, `AAAAAAAAAAA…`,
`01234567890…`, the Unicode title, `Focus`, active `Focus Right`, `Close`, and
`Renamed`.

## Centering and geometry

`title-pill-geometry.txt` records:

```text
output_width=1920
left=816
width=283
twice_center_error=5
```

The complete client strip center is x=957.5, within 2.5 pixels of the x=960
monitor center. The small difference is scanline antialiasing at the rounded
pill boundaries; the GTK strip is allocated by the outer `CenterBox` center
slot independently of unequal side groups.

`bar-geometry.txt` records a 1920 by 25 layer surface for initial, title, tray,
menu, and tray-removal states.

## Implementation exercised

- The Hyprland event task snapshots all mapped clients on the active workspace
  after initial startup, focus, title, open, close, move, regular workspace,
  and special-workspace events.
- The snapshot retains Hyprland's returned client order and identifies the
  active address separately.
- Active titles use the existing middle-cropped full-title behavior. Inactive
  titles use the first whitespace-delimited word, capped at 12 characters with
  an end ellipsis.
- GTK reconciles pills by Hyprland address, reuses widgets and cached icons,
  then appends them in snapshot order.

## Verification commands

```sh
nix develop -c cargo fmt -- --check
nix develop -c cargo test
nix develop -c cargo clippy --workspace --all-targets
nix build .#checks.x86_64-linux.gtk-status-bar-vm -L \
  --out-link result-workspace-client-pills-center_2026-07-13
```

The local source suite passed all 61 tests. Clippy completed with only the
repository's pre-existing warnings in `dbus.rs`, `pw.rs`, and existing test
module placement in `widgets.rs`.
