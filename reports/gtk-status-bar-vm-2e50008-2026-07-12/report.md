# VM evidence report: gtk-status-bar 2e50008

Date: 2026-07-12

Source revision: `2e50008a6c22c134a1b5c24e91968c3f818ae0fb`

Harness revision: `0e96dca`

The full NixOS graphical test completed successfully in 279.60 seconds. It
booted a UWSM-managed Hyprland session at 1920x480 with a 12-pixel cursor,
started the packaged bar and `trayctl`, launched fcitx5, Blueman, KDE Connect,
and Claude Desktop, exercised the external tray socket, and retained both QEMU
and in-session `grim` screenshots.

## Result

- PASS: the package contains both `gtk-status-bar` and the lightweight
  `trayctl` client; all 44 Rust tests passed in the Nix package build.
- PASS: the tray socket appeared at the documented path with directory mode
  0700 and socket mode 0600, owned by the session user.
- PASS: human and JSON list output reported four live tray items and exposed
  each item's activation mode.
- PASS: exact key, exact title, and numeric index targeting all opened the
  fcitx menu.
- PASS: `menu-next`, `menu-previous`, `menu-activate`, `menu-click`, and
  `close-menus` completed successfully. The journal records
  `MenuEvent(100)` and `MenuEvent(4)` for activation and direct click.
- PASS: moving next from no selection selected the first entry; moving previous
  from there wrapped visibly to the final `Exit` entry.
- PASS: the bar layer stayed exactly `(0, 0, 1920, 25)` with a long multibyte
  title, four tray items, an open menu, and after an item was removed.
- PASS: fcitx5, Blueman, KDE Connect, and Claude Desktop processes were live;
  four StatusNotifierItems appeared in the tray. KDE Connect removal was
  observed without a crash or resize.
- PASS: final service health, mouse input, restart supervision, and the existing
  workspace/title/battery/Bluetooth/PipeWire/clock matrix all passed.

## Visual evidence index

| Evidence | What it demonstrates |
| --- | --- |
| `41-tray-real-apps.png` | Four compact tray icons coexist with the top-flush, 25-pixel bar. |
| `42-trayctl-context-menu-key.png` | Socket command opens fcitx's native GTK menu at the tray. |
| `43-trayctl-menu-next.png` | First enabled entry is visibly selected. |
| `44-trayctl-menu-previous.png` | Reverse navigation wraps to the final `Exit` entry. |
| `45-trayctl-close-menus.png` | `close-menus` removes the popover while preserving bar geometry. |
| `47-trayctl-menu-activate.png` | Selected entry was activated and the menu closed. |
| `48-trayctl-menu-click.png` | Direct dbusmenu entry ID 4 was accepted and the menu closed. |
| `49-tray-fcitx-mozc.png` | Post-switch fcitx menu state; it remained English in this VM. |
| `50-tray-item-removed.png` | KDE Connect item removal leaves a healthy, unchanged-height bar. |
| `14-title-multibyte.png` | Long UTF-8 title is cropped without resizing the bar. |
| `38-bar-systemd-restarted.png` | Bar returned after SIGKILL; lifecycle evidence records a new PID. |

Every numbered image also has a `grim-` counterpart captured from inside the
Wayland session. Supporting evidence includes `bar-geometry.txt`,
`trayctl-list.json`, `trayctl-socket.txt`, `trayctl-menu-click.txt`,
`tray-processes.txt`, `tray-registered-items.txt`, and the full journal.

## Explicit gaps

- SKIPPED: menu-only `activate` could not be visually exercised because all
  four live applications reported `item_is_menu: false`. The result is recorded
  in `trayctl-menu-only-target.txt`; the implementation still handles the
  advertised true case in the request dispatcher.
- PARTIAL: `fcitx5-remote -s mozc` did not change the VM's displayed input
  method; `49-tray-fcitx-mozc.png` still shows `Keyboard - English (US)`.
  Menu display and socket control are proven, but English-to-Japanese switching
  is not claimed.
- CODE/UNIT COVERAGE: connection limits, oversized request rejection, timeout
  cancellation, accept retry, and IPC-server supervision are not visual states.
  They remain code/unit-test evidence rather than being overstated as VM visual
  passes.

## Reproduction

```sh
nix build .#checks.x86_64-linux.gtk-status-bar-vm -L
```
