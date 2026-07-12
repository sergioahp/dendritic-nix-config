# GTK status bar keyboard-menu evidence

Date: 2026-07-12

Result: PASS

The full NixOS graphical check completed successfully in 298.28 seconds. It
used the locally modified gtk-status-bar package in a UWSM-managed Hyprland
session and retained 141 evidence files in this directory.

## Result

- `trayctl keyboard-menu` acquired exclusive keyboard input through a separate
  transient 1x1 layer-shell helper surface. The long-lived bar remained on its
  normal bottom layer with keyboard interactivity disabled.
- The initial menu had exactly one explicit selection on the first enabled
  entry. `j`, Up, `G`, and `gg` moved that selection to next, previous, last,
  and first respectively.
- `q` and logical Escape (physical Caps Lock under `caps:swapescape`) closed the
  menu and destroyed the helper surface.
- Socket `close-menus`, a moved-pointer outside click, Enter activation, and an
  immediate keyboard-menu/close-menus race all released the helper surface.
- The same kitty address was active before and after the sequence. Its input
  log contains `baseline`, `qreturned`, `escapereturned`, `closereturned`,
  `clickreturned`, and `racereturned`.
- Ordinary `context-menu` and mouse-opened menu paths remained non-grabbing.

## Pointer-path nuance

An absolute pointer teleport combined with button events in one QMP request did
not dismiss the popup. This matches the path sensitivity seen with computer-use
tools: teleport, a real moved pointer, and socket navigation are not equivalent
inputs. The passing check sends eight separate pointer positions from the tray
anchor toward the client, waits for compositor delivery, and then sends button
down/up separately. That path dismissed the popup and returned input.

## Selection and rendering nuance

The explicit `.selected` style is stronger than GTK focus or hover: it uses an
accent background plus a blue inset marker. The initial neutral focus target
prevents GTK's last row from looking selected when the popup maps.

The headless VM sometimes shows only newly damaged popup rows on alternating
frames. The same behavior appears in ordinary socket screenshots 42/43, so it
is not specific to keyboard grabbing or helper-surface stacking. The live
desktop screenshots supplied by the user show the complete ordinary popup.

## Primary evidence

- `42-trayctl-context-menu-key.png` and `43-trayctl-menu-next.png`: unchanged
  ordinary socket path.
- `51-keyboard-menu-initial-first.png` through
  `55-keyboard-menu-gg-first.png`: initial and keyboard navigation states.
- `56-q-closed-focus-returned.png`,
  `57-escape-closed-focus-returned.png`, and
  `58-close-menus-released-focus.png`: close paths and returned input.
- `59-click-away-released-focus.png`: moved-pointer click-away path.
- `60-enter-activated-and-released.png`: Enter activation.
- `61-close-open-race-no-stale-grab.png`: stale-open race.
- `keyboard-focus-before.json`, `keyboard-focus-after.json`, and
  `keyboard-focus-returned.txt`: stable client identity and received lines.
- `gtk-status-bar-journal-full.log`: request IDs, received keys, and balanced
  acquire/release events.

