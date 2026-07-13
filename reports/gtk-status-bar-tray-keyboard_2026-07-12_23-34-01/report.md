# GTK status bar tray keyboard evidence

Date: 2026-07-12

The complete `gtk-status-bar-vm` check passed in 281.58 seconds with the bar
pinned to revision `a55a8d895155be2ac8a99c18b2402fde226f42a6`.

## Verified behavior

- `keyboard-menu` acquired exclusive keyboard focus only after its matching
  menu opened.
- Right/Left and `l`/`h` moved between tray icons without releasing the grab.
- Icon-level and menu-level `G`/`gg` moved to the last and first selections.
- `j` entered the menu at its first enabled row; Up wrapped to the last row.
- The first `q` and logical Escape returned from menu entries to icon level
  without releasing the grab. Their second press closed navigation and
  released keyboard focus.
- The first Enter selected the first enabled menu row. The second Enter
  activated it, closed navigation, and released keyboard focus.
- Socket `close-menus`, click-away dismissal, and the close/open race all left
  the previous application able to receive input.

The focused kitty window had the same Hyprland address before and after the
sequence. Its input log contains `qreturned`, `escapereturned`,
`closereturned`, `clickreturned`, `enterreturned`, and `racereturned`.

## Artifacts

- `51-keyboard-menu-icon-level.png` through
  `51e-keyboard-menu-first-icon.png`: icon-level navigation.
- `52-keyboard-menu-j-first-entry.png` through
  `55-keyboard-menu-G-last.png`: menu-row navigation.
- `55a-q-returned-to-icon-level.png` and
  `56-second-q-closed-focus-returned.png`: two-stage `q` behavior.
- `56a-escape-returned-to-icon-level.png` and
  `57-second-escape-closed-focus-returned.png`: two-stage Escape behavior.
- `58-close-menus-released-focus.png` and
  `59-click-away-released-focus.png`: external close paths.
- `60-enter-selected-first-entry.png` and
  `60a-second-enter-activated-and-released.png`: two-stage Enter behavior.
- `61-close-open-race-no-stale-grab.png`: canceled-open race behavior.
- `keyboard-focus-before.json`, `keyboard-focus-after.json`, and
  `keyboard-focus-returned.txt`: focus identity and returned-input evidence.
