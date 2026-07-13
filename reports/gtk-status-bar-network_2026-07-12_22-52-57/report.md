# Adaptive network status evidence

Date: 2026-07-12 (America/Mexico_City)

## Scope

The VM uses a NetworkManager D-Bus mock for event-driven link changes and real
ICMP probes against TEST-NET addresses. One address is made reachable through
the loopback interface during the test. DejaVu Sans Mono Nerd Font is installed
in the guest, matching the desktop configuration.

## Results

| State | Expected pill | Result |
| --- | --- | --- |
| Wi-Fi 73%, probes failing for the confirmation window | strength-3 icon, `73%`, `x` | Passed |
| Wi-Fi 73%, reachable target | strength-3 icon, `73%`, globe | Passed |
| Wi-Fi strength event changes to 28% | strength-1 icon, `28%`, globe | Passed |
| Primary connection changes to wired | Ethernet icon, globe | Passed |
| NetworkManager reports no active connection | network-off icon, `x` | Passed |

The journal also records the randomized probe results and every D-Bus-driven
label transition. The bar retained identical geometry before and after a long
multibyte title: `(0, 0, 1920, 25)`.

## Artifacts

- `01a-network-wifi-offline.png`
- `01b-network-wifi-online.png`
- `01c-network-wifi-weak.png`
- `01d-network-wired-online.png`
- `01e-network-disconnected.png`
- `gtk-status-bar-journal-initial.log`
- `bar-geometry.txt`

## Full-suite status

The network feature sequence and all subsequent checks through the tray menu
keyboard-focus setup passed. The full derivation later stopped at the existing
`Closing tray menu from keyboard` timeout. The same unrelated assertion failed
in the immediately preceding pre-Nerd-Font run; no network assertion or bar
geometry assertion failed.
