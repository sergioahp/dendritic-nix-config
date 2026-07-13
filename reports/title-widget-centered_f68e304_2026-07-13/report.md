# Centered title widget content evidence

Date: 2026-07-13

Source revision: `f68e3044a18e8ebac151cee44c0fb01ef2887a85`

Evidence harness revision: `93db01b98d1b8f4e15d4570579981df8cdcc8f24`

## Result

- PASS: the application icon and short title are centered together as one
  content group inside the title pill.
- PASS: the title pill retains its existing 10em minimum width when its content
  is narrower.
- PASS: the icon remains on the left side of the title and shares the title
  pill's background and workspace color.
- PASS: the bar stayed 25 pixels tall for the initial, title, tray, menu, and
  tray-removal states.
- PASS: the complete NixOS/Hyprland VM regression test finished successfully in
  313.35 seconds.

## Visual evidence

| File | Demonstrates |
| --- | --- |
| `11-title-short-closeup.png` | The kitty icon and `hello` are centered as a group within the wider blue pill. |
| `03-kitty-title-closeup.png` | A longer initial Kitty title remains centered with its icon. |
| `11-title-short.png` | Full-monitor runtime context for the short-title case. |
| `03-kitty-title.png` | Full-monitor runtime context for the initial Kitty title. |
| `15-focus-left.png` | Centered title content follows focus to `Focus Left`. |
| `16-focus-right.png` | Centered title content follows focus to `Focus Right`. |

The close-ups are independent crops of their corresponding full-monitor
captures. No screenshots were combined.

## Runtime evidence

The full journal confirms that the short title retained the Kitty application
class and icon:

```text
Resolved title icon from desktop application metadata class="kitty"
Updating title widget title="hello" class="kitty"
```

`bar-geometry.txt` records:

```text
initial=(0, 0, 1920, 25)
title=(0, 0, 1920, 25)
tray=(0, 0, 1920, 25)
menu=(0, 0, 1920, 25)
removed=(0, 0, 1920, 25)
```

`gtk-status-bar-status.txt` records the packaged bar running under the user
service. `gtk-status-bar-journal-full.log` contains the complete structured
runtime log.

## Verification commands

```sh
nix develop -c cargo fmt
nix develop -c cargo test
nix develop -c cargo clippy --workspace --all-targets
nix build .#checks.x86_64-linux.gtk-status-bar-vm -L \
  --out-link result-title-centered_2026-07-13
```

The local unit suite passed 58 tests. The pinned release package passed 58
application tests, 3 tray IPC tests, and 2 trayctl tests before the VM test ran.
Clippy completed with the repository's pre-existing warnings in `dbus.rs`,
`pw.rs`, and the existing test-module placement in `widgets.rs`.
