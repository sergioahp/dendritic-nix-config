# Monitor-centered title pill evidence

Date: 2026-07-13

Source revision: `6e59b7b01f362c9b6f37389052bd11d0f812b5e9`

Evidence harness revision: `a98d2fb5d763f269ff5c5848a43d721f32d4e10b`

## Result

- PASS: the title pill is centered on the 1920 pixel output independently of
  the unequal left and right widget group widths.
- PASS: the pill center aligns with the x=960 boundary between two tiled Kitty
  clients.
- PASS: the existing 10em minimum pill width and the title widget's icon/label
  layout are retained.
- PASS: the bar stayed 25 pixels tall for the initial, title, tray, menu, and
  tray-removal states.
- PASS: the complete NixOS/Hyprland VM regression test finished successfully in
  303.41 seconds.

## Geometry evidence

`title-pill-geometry.txt` records:

```text
output_width=1920
left=872
width=177
twice_center_error=1
```

The pill center is x=960.5. The output center and two-client tiling boundary are
x=960, leaving only the expected half-pixel rounding from an odd-width widget.

The same scanline measurement against the prior `f68e304` capture found the
pill at x=737 with width 177: center x=825.5, or 134.5 pixels left of the
monitor center. The VM now enforces a maximum one-pixel center difference and
would reject that prior allocation.

## Visual evidence

| File | Demonstrates |
| --- | --- |
| `11-title-short-closeup.png` | The pill center sits directly above the vertical boundary between the two tiled clients. |
| `before-f68e304-title-short-closeup.png` | Independent prior capture showing the pill visibly left of that boundary. |
| `11-title-short.png` | Full-monitor runtime context with unequal side groups and two tiled clients. |
| `03-kitty-title.png` | Initial Kitty title remains monitor-centered. |
| `15-focus-left.png` | Centering remains stable after focusing the left client. |
| `16-focus-right.png` | Centering remains stable after focusing the right client. |

The close-ups are independent crops; no screenshots were combined.

## Implementation

The previous outer `gtk4::Box` distributed spare width between two expanding
spacers. Once the dynamic right group exceeded the historical 20em side
container width, the remaining spaces were no longer symmetric around the
monitor midpoint.

The outer bar now uses `gtk4::CenterBox` with the workspace group in its start
slot, the title pill in its center slot, and status widgets in its end slot.
GTK therefore positions the title independently of the side allocations.

`bar-geometry.txt` records:

```text
initial=(0, 0, 1920, 25)
title=(0, 0, 1920, 25)
tray=(0, 0, 1920, 25)
menu=(0, 0, 1920, 25)
removed=(0, 0, 1920, 25)
```

## Verification commands

```sh
nix develop -c cargo fmt -- --check
nix develop -c cargo test
nix develop -c cargo clippy --workspace --all-targets
nix build .#checks.x86_64-linux.gtk-status-bar-vm -L \
  --out-link result-title-monitor-centered_2026-07-13
```

The local unit suite passed 58 tests. The pinned release package passed 58
application tests, 3 tray IPC tests, and 2 trayctl tests before the VM test ran.
Clippy completed with the repository's pre-existing warnings in `dbus.rs`,
`pw.rs`, and the existing test-module placement in `widgets.rs`.
