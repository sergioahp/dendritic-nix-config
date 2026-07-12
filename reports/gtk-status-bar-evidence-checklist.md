# gtk-status-bar VM evidence checklist

This checklist covers the current master implementation, including the system
tray, external tray socket control, and the font-derived bar sizing refactor.
Every visual state is captured twice by the NixOS test driver: once through its
QEMU screenshot support and once inside the Wayland session with `grim`.

## Startup and layout

- [ ] The user service starts, maps one `gtk4-layer-shell` bottom-layer surface,
  and remains active.
- [ ] The bar starts at `(0, 0)`, spans the 1920-pixel output, and keeps one
  font-derived height.
- [ ] Pills are flush with the top edge, retain the U-shaped/squarish styling,
  and do not introduce a gap above the bar.
- [ ] Short, exactly 64-character, cropped ASCII, and cropped multibyte titles
  do not change the layer geometry.
- [ ] Adding several tray icons, opening a tray menu, and removing a tray icon
  do not change the layer geometry.
- [ ] Tray icons occupy approximately one tall character cell and align with
  the adjacent text without making the bar taller.

## Existing widget behavior

- [ ] Workspace changes cover configured colors, fallback colors, named and
  unnamed special workspaces, injected key bindings, and an update burst.
- [ ] Window titles cover focus changes and UTF-8-safe middle cropping.
- [ ] UPower covers initial state, live changes, 0%, 100%, rounding, charging,
  and removal behavior.
- [ ] BlueZ covers initial state, multiple devices, Unicode aliases, property
  updates, and device removal.
- [ ] PipeWire covers default sink selection, volume changes, mute, 0%, 100%,
  and default-sink removal.
- [ ] The clock is captured on both sides of a real minute transition.
- [ ] A forced service crash produces a new PID and increments `NRestarts`.

## Real tray applications

- [ ] fcitx5, Blueman, KDE Connect, and Claude Desktop are launched in the real
  UWSM/Hyprland user session.
- [ ] At least three StatusNotifierItems register and render simultaneously.
- [ ] The registered item list and process list are saved as text evidence.
- [ ] fcitx can switch to Mozc and still exposes its menu through the bar.
- [ ] Stopping KDE Connect removes its item without resizing or crashing the
  bar.

## trayctl and socket control

- [ ] `trayctl --help` writes normal usage and exits successfully.
- [ ] `trayctl socket-path` reports
  `/run/user/1000/gtk-status-bar/tray.sock`.
- [ ] The socket directory is mode 0700 and the socket is mode 0600, both owned
  by the session user.
- [ ] Human and JSON list output can enumerate the live tray items.
- [ ] Exact item keys, exact titles, and zero-based indexes resolve correctly.
- [ ] `context-menu` opens the selected application's native GTK popover.
- [ ] A newly opened non-grabbing menu has no spurious last-row selection.
- [ ] `menu-next` and `menu-previous` visibly move the selected entry.
- [ ] Selection navigation wraps and can traverse enabled submenu entries.
- [ ] `menu-activate` activates the selected entry and closes the popover.
- [ ] `menu-click` accepts a live dbusmenu entry ID, activates it, and closes the
  popover.
- [ ] `close-menus` closes all open tray popovers.
- [ ] `keyboard-menu` takes exclusive focus only after its matching popover
  opens, and ordinary socket- and mouse-opened menus remain non-grabbing.
- [ ] Arrow keys and nvim `j`/`k`, `gg`/`G`, and `h`/`l` navigation update the
  same single visual selection used by the socket commands.
- [ ] Enter activates a leaf (or enters a submenu), while Escape and `q` close
  the popover and release the grab.
- [ ] A click-away dismissal and `close-menus` also release an active grab.
- [ ] After every close path, an injected key reaches the window that was
  focused immediately before `keyboard-menu`.
- [ ] Close/open races cannot display a canceled menu or acquire a stale grab;
  a menu that fails to open never acquires focus.
- [ ] `activate` opens an item marked `ItemIsMenu`, matching physical left-click
  behavior.
- [ ] Menu IPC uses the real tray button coordinates for any SNI fallback.
- [ ] An unavailable or failed tray IPC server cannot stop tray item updates or
  menus; server setup retries with bounded exponential backoff.
- [ ] A client that times out cannot execute its queued UI action later.
- [ ] Oversized requests and excess concurrent clients are bounded.

The last four hardening items are primarily code/unit-test assertions. The VM
run proves the live socket, client, GTK menu model, application D-Bus services,
and non-resizing visual states end to end; its report must distinguish those
visual results from hardening behavior covered outside the VM.
