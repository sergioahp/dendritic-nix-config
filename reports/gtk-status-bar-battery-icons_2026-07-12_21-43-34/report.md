# gtk-status-bar battery icon evidence

Run started on 2026-07-12 with the local gtk-status-bar working tree supplied
through a Nix flake input override:

```sh
nix build .#checks.x86_64-linux.gtk-status-bar-vm \
  --override-input gtk-status-bar path:/home/admin/code/rust/gtk-status-bar -L
```

## Battery assertions

The NixOS test booted a real UWSM-managed Hyprland session, ran the packaged
GTK bar, and drove a python-dbusmock UPower service over the system bus. All
battery-specific assertions completed successfully:

| Input | Expected label | Result |
| --- | --- | --- |
| Initial 73%, discharging | 🔋 73% | Passed |
| 42%, discharging | 🔋 42% | Passed |
| State-only change to charging | ⚡ 42% | Passed |
| 20%, discharging | 🪫 20% | Passed |
| 100%, fully charged | 🔌 100% | Passed |
| 79.5%, discharging | 🔋 80% | Passed |

The state-only charging case intentionally omitted Percentage from the D-Bus
signal. This verifies that the bar retains the last percentage and recomputes
the label when only UPower State changes.

Each visual state was captured both through the QEMU test driver and from
inside the Wayland session with grim. The grim captures were inspected and
show the expected icons and percentages in the battery pill.

## Full-suite outcome

The full legacy evidence check continued past the battery section through
Bluetooth, PipeWire, D-Bus recovery, systemd restart, clock, and tray tests. It
later failed in the keyboard-menu section, unrelated to the battery change.
The injected `q` reached gtk-status-bar and was logged as `cmd=Escape`, but the
test timed out waiting for the older `Closing tray menu from keyboard` log.

Battery evidence remains valid: every battery assertion and screenshot
completed before that later failure. The failed derivation retained the output
artifacts copied into this directory.
