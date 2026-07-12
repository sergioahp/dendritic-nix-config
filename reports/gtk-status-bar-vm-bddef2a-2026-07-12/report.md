# VM evidence report: gtk-status-bar bddef2a

Date: 2026-07-12

Source revision: `bddef2aafb97974bc01227bfeaef5e2b937342bd`

The full NixOS graphical test completed successfully in 254.97 seconds. It
booted a UWSM-managed Hyprland session at 1280x800, started the user service,
used python-dbusmock for UPower and BlueZ, used real PipeWire with null sinks,
sent Hyprland IPC commands and test-driver keystrokes, captured in-session
`grim` screenshots, and asserted final service health.

The VM test result was copied from the Nix result into this directory. The
primary artifacts are the numbered PNGs, `gtk-status-bar-journal-full.log`,
`gtk-status-bar-status.txt`, `bar-lifecycle.txt`, `mouse-evidence.txt`,
`hyprctl-layers.txt`, `hyprland-version.txt`, and `uwsm-session-units.txt`.

## Summary

- PASS: cold startup seeded battery 73% and Bluetooth `P80`.
- PASS: title, workspace, special-workspace, battery, Bluetooth, PipeWire,
  focus, keyboard, mouse, clock, and systemd restart paths produced visual
  evidence.
- PASS: the new BlueZ `PropertiesChanged` subscription updated an existing
  device from `P80` to `P65`.
- PASS: `InterfacesRemoved` removed devices from the display and hid the
  Bluetooth widget after the last device disappeared.
- DOCUMENTED GAP: removing the UPower battery leaves its last label visible.
- DOCUMENTED GAP: stopping only mock service owners does not drop the shared
  system-bus connection, so it cannot prove the monitor's reconnect backoff.
- SKIPPED: a no-owner baseline, an isolated system-bus outage, exact
  Battery1-first then Device1 ordering, and an isolated Hyprland IPC outage
  were not driven by this script.

## Checklist results

| Item | Status | Evidence / observation |
| --- | --- | --- |
| S1 | PASS | `01-bar-initial.png`: `P80`, battery `73%`; journal records both initial seeds. |
| S2 | PASS | Initial journal contains GTK, title/workspace, D-Bus, layer-shell, and activation startup lines. |
| S3 | SKIPPED | This run did not include the separate no-owner baseline. |
| W1 | PASS | `02`, `06`, and `07` show workspaces 2, 10, and 11 with distinct/fallback colors. |
| W2 | PASS | `07-workspace-11-fallback.png` shows `Workspace 11`. |
| W3 | PASS / PARTIAL | `08-special-workspace-named.png` shows `Special: evidence`; the unnamed attempt resolved to `Special: special`, so the empty-name fallback was not isolated. |
| W4 | PASS | `04-sendkey-workspace-1.png` follows a real test-driver `Alt+1` binding. |
| W5 | PASS | `10-workspace-burst-final-10.png` reaches the final workspace without a crash. |
| T1 | PASS | The title is empty after killing the focused window while the pill remains present. |
| T2 | PASS | `11-title-short.png` shows `hello`. |
| T3 | PASS | `12-title-exactly-64.png` shows the exact-length title without an ellipsis. |
| T4 | PASS | `13-title-cropped.png` shows middle cropping with an ellipsis. |
| T5 | PASS | `14-title-multibyte.png` shows clean CJK/emoji character-boundary cropping. |
| T6 | PASS | `15-focus-left.png` and `16-focus-right.png` follow explicit focus changes. |
| B1 | PASS | `01-bar-initial.png` and the initial journal show 73%. |
| B2 | PASS | `19-battery-42-discharging.png` follows a live 73 to 42 update. |
| B3 | DOCUMENTED GAP | `20-battery-charging-text-unchanged.png`; state transitions are logged while the percentage label remains unchanged. |
| B4 | PASS | `21`, `22`, and `23` show 0%, 100%, and 79.5 rounded to 80%. |
| B5 | DOCUMENTED GAP | `24-battery-removed-stale.png` retains the last battery label. |
| BT1 | SKIPPED | No-owner baseline was not repeated in this run. |
| BT2 | PASS | Initial `P80`; `25-bluetooth-three-devices.png` retains the named device. |
| BT3 | PASS | `25` includes the battery-only fallback device `D42`. |
| BT4 | PASS | `25` includes the headphone character plus `55`, proving character rather than byte selection. |
| BT5 | PASS | `25` shows the three-device joined display. |
| BT6 | PASS | `26-bluetooth-properties-changed-known-bug.png` follows the live update to `P65`; the journal records `Updated device ... via PropertiesChanged`. |
| BT7 | PASS | `27` removes Pixel Buds and `28-bluetooth-all-removed-hidden.png` hides the widget after all removals. |
| BT8 | SKIPPED | The exact battery-first/name-later signal order was not separately emitted; it is covered by forged-message unit tests in the Rust repository. |
| V1 | PASS | `29-volume-alpha-50.png` shows the real PipeWire null sink at 50%. |
| V2 | PASS | `30-volume-alpha-75.png` follows a live volume change. |
| V3 | PASS | `31-volume-muted.png` changes the icon; unmute restores it. |
| V4 | PASS | `32-volume-zero.png` and `33-volume-100.png` cover both edges. |
| V5 | PASS | `34-volume-default-bravo.png` changes the sink initial to `B`. |
| V6 | PASS | `35-volume-default-removed.png` falls back to the remaining sink. |
| R1 | SKIPPED | Stopping only mock owners leaves the system-bus connection alive; killing the system broker also destroys the UWSM session, so isolated monitor backoff was not claimed. |
| R2 | DOCUMENTED GAP | Owner recovery was captured, but the script manually restarted the bar before reseeding; this is not proof of supervisor reconnect/reseed. |
| R3 | SKIPPED | Depends on the isolated system-bus outage from R1. |
| R4 | DOCUMENTED GAP | `36-service-owners-missing-stale-state.png` captures stale labels while owners are down. |
| R5 | PASS | `38-bar-systemd-restarted.png`; `bar-lifecycle.txt` records a new PID and `NRestarts=1`. |
| R6 | SKIPPED | Isolating Hyprland IPC would invalidate the graphical session. |
| C1 | PASS | `39-clock-before-minute.png` and `40-clock-after-minute.png` straddle a minute boundary. |

## Environment notes

The VM uses software rendering and has no physical battery, Bluetooth radio,
or sound card. dbusmock and PipeWire null sinks exercise the real D-Bus and
PipeWire interfaces consumed by the bar. The Hyprland startup warning about
running without `start-hyprland` is retained in the screenshots; UWSM session
units and a stable graphical session establish the ownership model used here.

The VM emitted a Hyprland SIGSEGV while powering off after all assertions and
artifact saves had completed. This is a teardown event, not a failed checklist
assertion.

Reproduce from this repository with:

```sh
nix build .#checks.x86_64-linux.gtk-status-bar-vm -L
```
