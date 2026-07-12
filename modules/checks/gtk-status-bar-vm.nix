{ inputs, ... }: {
  # End-to-end evidence VM for gtk-status-bar (pinned in flake.nix to the rev
  # under test). Mirrors the laptop environment: a normal "admin" user, the
  # latest Hyprland, and the bar's home-manager service started from Hyprland's
  # exec-once after import-environment, exactly like the real hyprland.nix in
  # the home-manager config repo.
  #
  # Run with:  nix build .#checks.x86_64-linux.gtk-status-bar-vm -L
  # Artifacts (screenshots, journal excerpts) land in ./result.
  #
  # The whole test rides nixpkgs-hm rather than the system nixpkgs pin: the
  # laptop runs the latest Hyprland and nixpkgs-hm is the faster-moving input
  # (0.55.x there vs 0.52.x on the nixos-unstable pin), so compositor,
  # home-manager and the test framework agree on one recent pkgs.
  #
  # No GPU on this desktop: QEMU exposes a virtio-gpu KMS device and Hyprland
  # renders through mesa llvmpipe. This is the exact setup Hyprland's own CI
  # uses for its NixOS VM test (nix/tests/default.nix in hyprwm/Hyprland),
  # including the 8G "might crash with less" memory floor.
  perSystem = { system, ... }:
    let
      pkgs = import inputs.nixpkgs-hm { inherit system; };
      mockPython = pkgs.python3.withPackages (ps: [ ps.python-dbusmock ]);
      dbusMockPolicy = pkgs.writeTextDir "share/dbus-1/system.d/gtk-status-bar-mocks.conf" ''
        <!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
          "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
        <busconfig>
          <policy user="root">
            <allow own="org.freedesktop.UPower"/>
            <allow own="org.bluez"/>
          </policy>
          <policy context="default">
            <allow send_destination="org.freedesktop.UPower"/>
            <allow send_destination="org.bluez"/>
          </policy>
        </busconfig>
      '';
      mockControl = pkgs.writeScriptBin "gtk-status-bar-mock-control" ''
        #!${mockPython}/bin/python
        import sys
        import time

        import dbus

        MOCK_IFACE = "org.freedesktop.DBus.Mock"
        UPOWER_DEVICE = "org.freedesktop.UPower.Device"
        BLUEZ_MOCK = "org.bluez.Mock"
        BLUEZ_BATTERY = "org.bluez.Battery1"


        def wait_name(bus, name):
            for _ in range(100):
                if bus.name_has_owner(name):
                    return
                time.sleep(0.1)
            raise RuntimeError(f"D-Bus name did not appear: {name}")


        def bluez_device(bus, bluez, address, alias, percentage):
            path = bluez.AddDevice("hci0", address, alias)
            obj = bus.get_object("org.bluez", path)
            dbus.Interface(obj, MOCK_IFACE).AddProperties(
                BLUEZ_BATTERY,
                {"Percentage": dbus.Byte(percentage)},
            )
            return str(path)


        bus = dbus.SystemBus()
        action = sys.argv[1]

        if action in {"initial", "recovery", "post-recovery"}:
            wait_name(bus, "org.freedesktop.UPower")
            wait_name(bus, "org.bluez")
            upower_obj = bus.get_object("org.freedesktop.UPower", "/org/freedesktop/UPower")
            upower = dbus.Interface(upower_obj, MOCK_IFACE)
            bluez_obj = bus.get_object("org.bluez", "/")
            bluez = dbus.Interface(bluez_obj, BLUEZ_MOCK)
            bluez.AddAdapter("hci0", "VM adapter")
            if action == "initial":
                upower.AddDischargingBattery("battery_BAT0", "VM battery", 73.0, 3600)
                bluez_device(bus, bluez, "AA:BB:CC:DD:EE:01", "Pixel Buds", 80)
            elif action == "recovery":
                upower.AddDischargingBattery("battery_BAT0", "VM battery", 55.0, 1800)
                bluez_device(bus, bluez, "AA:BB:CC:DD:EE:09", "Recovery Buds", 65)
            else:
                upower.AddDischargingBattery("battery_BAT0", "VM battery", 33.0, 900)
                bluez_device(bus, bluez, "AA:BB:CC:DD:EE:10", "Post Recovery Buds", 77)
        elif action == "battery":
            percentage = float(sys.argv[2])
            state = int(sys.argv[3])
            upower_obj = bus.get_object("org.freedesktop.UPower", "/org/freedesktop/UPower")
            dbus.Interface(upower_obj, MOCK_IFACE).SetDeviceProperties(
                "/org/freedesktop/UPower/devices/battery_BAT0",
                {
                    "Percentage": dbus.Double(percentage),
                    "State": dbus.UInt32(state),
                },
            )
        elif action == "battery-remove":
            upower_obj = bus.get_object("org.freedesktop.UPower", "/org/freedesktop/UPower")
            dbus.Interface(upower_obj, MOCK_IFACE).RemoveDevice(
                "/org/freedesktop/UPower/devices/battery_BAT0"
            )
        elif action == "bluez-extras":
            root = bus.get_object("org.bluez", "/")
            root_mock = dbus.Interface(root, MOCK_IFACE)
            root_mock.AddObject(
                "/org/bluez/hci0/dev_AA_BB_CC_DD_EE_02",
                BLUEZ_BATTERY,
                {"Percentage": dbus.Byte(42)},
                [],
            )
            bluez = dbus.Interface(root, BLUEZ_MOCK)
            bluez_device(bus, bluez, "AA:BB:CC:DD:EE:03", "\U0001F3A7 Sony", 55)
        elif action == "bluez-percentage":
            percentage = int(sys.argv[2])
            path = "/org/bluez/hci0/dev_AA_BB_CC_DD_EE_01"
            obj = bus.get_object("org.bluez", path)
            dbus.Interface(obj, dbus.PROPERTIES_IFACE).Set(
                BLUEZ_BATTERY,
                "Percentage",
                dbus.Byte(percentage),
            )
        elif action == "bluez-remove":
            path = sys.argv[2]
            adapter = bus.get_object("org.bluez", "/org/bluez/hci0")
            dbus.Interface(adapter, "org.bluez.Adapter1").RemoveDevice(path)
        else:
            raise SystemExit(f"unknown action: {action}")
      '';
    in {
      checks.gtk-status-bar-vm = pkgs.testers.runNixOSTest {
        name = "gtk-status-bar-vm";

        nodes.machine = { config, pkgs, ... }: {
          imports = [ inputs.home-manager.nixosModules.home-manager ];

          # Mirror of the real admin user (modules/nixos/user.nix), plus the
          # ydotool group for uinput-level mouse/keyboard injection.
          users.users.admin = {
            isNormalUser = true;
            extraGroups = [ "wheel" "ydotool" ];
          };

          # Keep the real session ownership model (UWSM-managed Hyprland), but
          # replace SDDM with tty1 autologin so the headless test is deterministic.
          services.getty.autologinUser = "admin";
          programs.bash.loginShellInit = ''
            if [ "$(tty)" = "/dev/tty1" ]; then
              exec uwsm start -F -- /run/current-system/sw/bin/Hyprland
            fi
          '';

          programs.hyprland = {
            enable = true;
            withUWSM = true;
          };
          programs.uwsm.waylandCompositors.hyprland = {
            prettyName = "Hyprland";
            comment = "Hyprland compositor managed by UWSM";
            binPath = "/run/current-system/sw/bin/Hyprland";
          };

          # uinput-backed input injection usable from the test driver (root is
          # outside the compositor, so wtype/hyprctl cover wayland-side input
          # and ydotool covers "real device" input).
          programs.ydotool.enable = true;

          services.pipewire.enable = true;
          services.dbus.packages = [ dbusMockPolicy ];
          security.rtkit.enable = true;

          # speechd is pulled in by default and only fattens the closure
          services.speechd.enable = pkgs.lib.mkForce false;

          fonts.packages = with pkgs; [
            dejavu_fonts
            noto-fonts
            noto-fonts-color-emoji
          ];

          environment.systemPackages = with pkgs; [
            adwaita-icon-theme
            blueman
            fcitx5
            kitty
            kdePackages.kdeconnect-kde
            grim
            jq
            mockControl
            pulseaudio
            wl-clipboard
            inputs.llm-agents.packages.${system}.claude-desktop
          ];

          systemd.services.dbusmock-upower = {
            description = "Mock UPower for gtk-status-bar evidence";
            wantedBy = [ "multi-user.target" ];
            before = [ "getty@tty1.service" ];
            serviceConfig = {
              ExecStart = "${mockPython}/bin/python -m dbusmock --system --template upower --logfile /var/log/dbusmock-upower.log";
              Restart = "on-failure";
            };
          };
          systemd.services.dbusmock-bluez = {
            description = "Mock BlueZ for gtk-status-bar evidence";
            wantedBy = [ "multi-user.target" ];
            before = [ "getty@tty1.service" ];
            serviceConfig = {
              ExecStart = "${mockPython}/bin/python -m dbusmock --system --template bluez5 --logfile /var/log/dbusmock-bluez.log";
              Restart = "on-failure";
            };
          };
          systemd.services.dbusmock-seed = {
            description = "Seed mock hardware before the graphical session";
            wantedBy = [ "multi-user.target" ];
            requires = [ "dbusmock-upower.service" "dbusmock-bluez.service" ];
            after = [ "dbusmock-upower.service" "dbusmock-bluez.service" ];
            before = [ "getty@tty1.service" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${mockControl}/bin/gtk-status-bar-mock-control initial";
              RemainAfterExit = true;
            };
          };

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.admin = {
            imports = [ inputs.gtk-status-bar.homeModules.default ];
            home.stateVersion = "25.11";

            programs.gtk-status-bar = {
              enable = true;
              # debug so the journal shows the widget update lines
              # ("Updating workspace - label", "Updating title label")
              logLevel = "debug";
            };

            gtk.iconTheme = {
              name = "Adwaita";
              package = pkgs.adwaita-icon-theme;
            };

            i18n.inputMethod = {
              enable = true;
              type = "fcitx5";
              fcitx5.addons = with pkgs; [
                fcitx5-mozc
                fcitx5-gtk
                kdePackages.fcitx5-qt
              ];
              fcitx5.waylandFrontend = true;
            };

            services.kdeconnect = {
              enable = true;
              indicator = false;
            };

            # Trimmed mirror of modules/hyprland.nix from the home-manager
            # config repo: same workspace defaultNames, same exec-once
            # import-environment + service start dance, animations off.
            # package/portalPackage null: the NixOS programs.hyprland above
            # provides the binary; home-manager only writes the config.
            wayland.windowManager.hyprland = {
              enable = true;
              package = null;
              portalPackage = null;
              systemd.enable = false;
              settings = {
                "$mod" = "SUPER";
                monitor = [ ",1920x480@60,auto,1" ];
                workspace = [
                  "1, defaultName:u"
                  "2, defaultName:i"
                  "3, defaultName:o"
                  "4, defaultName:p"
                  "5, defaultName:j"
                  "6, defaultName:k"
                  "7, defaultName:l"
                  "8, defaultName:s"
                  "9, defaultName:m"
                  "10, defaultName:c"
                ];
                general = {
                  gaps_in = 3;
                  gaps_out = 4;
                  "col.active_border" = "rgba(05d0e866) rgba(450086ff) 20deg";
                  "col.inactive_border" = "rgba(00000000)";
                  border_size = 5;
                };
                input = {
                  kb_layout = "us";
                  kb_variant = "altgr-intl";
                  kb_options = "caps:swapescape";
                  repeat_delay = 275;
                  repeat_rate = 26;
                  follow_mouse = 1;
                  sensitivity = 0;
                };
                animations.enabled = false;
                misc = {
                  disable_hyprland_logo = true;
                  focus_on_activate = true;
                };
                # software cursor: no GPU in the VM
                cursor.no_hardware_cursors = true;
                env = [
                  "XCURSOR_SIZE,12"
                  "HYPRCURSOR_SIZE,12"
                ];
                # ALT instead of SUPER so the qemu test driver's send_key can
                # reach them ("alt-2" injects reliably, super does not).
                bind = [
                  "ALT, 1, workspace, 1"
                  "ALT, 2, workspace, 2"
                  "ALT, 3, workspace, 3"
                  "ALT, RETURN, exec, kitty"
                ];
                exec-once = [
                  # Same two lines as the real config: uwsm normally exports
                  # WAYLAND_DISPLAY etc., but HYPRLAND_INSTANCE_SIGNATURE is
                  # only known once Hyprland is up; re-import so the systemd
                  # user service can find Hyprland's IPC sockets.
                  "systemctl --user import-environment HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
                  "systemctl --user start gtk-status-bar.service"
                ];
              };
            };
          };

          virtualisation = {
            cores = 4;
            # Hyprland's own CI test: "Might crash with less"
            memorySize = 8192;
            resolution = { x = 1920; y = 480; };
            qemu.options = [ "-vga none -device virtio-gpu-pci" ];
          };
        };

        testScript = ''
          import os
          import json
          import re
          import shlex
          from typing import Any, cast

          outdir = os.environ.get("out", os.getcwd())

          machine.wait_for_unit("multi-user.target")

          machine.wait_until_succeeds(
              "systemctl --user -M admin@ is-active wayland-wm@Hyprland.service",
              timeout=180,
          )

          # exec-once import-environment publishes the session env into the
          # systemd user manager; that is also our source of truth for driving
          # commands as admin.
          machine.wait_until_succeeds(
              "systemctl --user -M admin@ show-environment | grep -q '^WAYLAND_DISPLAY='",
              timeout=120,
          )
          user_env = machine.succeed("systemctl --user -M admin@ show-environment")
          wl = [l for l in user_env.splitlines() if l.startswith("WAYLAND_DISPLAY=")][0].split("=", 1)[1]
          his = [l for l in user_env.splitlines() if l.startswith("HYPRLAND_INSTANCE_SIGNATURE=")][0].split("=", 1)[1]
          print(f"WAYLAND_DISPLAY={wl} HYPRLAND_INSTANCE_SIGNATURE={his}")

          def admin(cmd, check=True):
              full = (
                  "env XDG_RUNTIME_DIR=/run/user/1000"
                  f" WAYLAND_DISPLAY={wl}"
                  f" HYPRLAND_INSTANCE_SIGNATURE={his} " + cmd
              )
              wrapped = f"su - admin -c {shlex.quote(full)}"
              if check:
                  return machine.succeed(wrapped)
              return machine.execute(wrapped)

          def save(name, text):
              with open(os.path.join(outdir, name), "w") as f:
                  f.write(text)

          def shot(name):
              machine.screenshot(name)
              admin(f"grim /tmp/grim-{name}.png")
              machine.copy_from_machine(f"/tmp/grim-{name}.png", outdir)

          def wait_log(needle, timeout=60):
              quoted = shlex.quote(needle)
              machine.wait_until_succeeds(
                  "journalctl _SYSTEMD_USER_UNIT=gtk-status-bar.service --no-pager"
                  f" | grep -Fq -- {quoted}",
                  timeout=timeout,
              )

          def bar_geometry():
              layers = admin("hyprctl layers")
              for line in layers.splitlines():
                  if "namespace: gtk4-layer-shell" not in line:
                      continue
                  match = re.search(r"xywh: (-?\d+) (-?\d+) (\d+) (\d+)", line)
                  if match:
                      return tuple(int(value) for value in match.groups())
              raise AssertionError(f"gtk-status-bar layer geometry not found:\n{layers}")

          def launch_title(title):
              command = f"kitty --title {shlex.quote(title)} sh -c 'sleep 600'"
              admin(f"hyprctl dispatch exec -- {shlex.quote(command)}")
              expected = shlex.quote(title)
              machine.wait_until_succeeds(
                  "su - admin -c " + shlex.quote(
                      "env XDG_RUNTIME_DIR=/run/user/1000"
                      f" HYPRLAND_INSTANCE_SIGNATURE={his}"
                      f" hyprctl activewindow -j | jq -e --arg t {expected} '.title == $t'"
                  ),
                  timeout=60,
              )

          # --- Evidence 1: service starts and stays up -----------------------
          machine.wait_until_succeeds(
              "systemctl --user -M admin@ is-active gtk-status-bar.service",
              timeout=120,
          )
          machine.wait_until_succeeds(
              "test -S /run/user/1000/gtk-status-bar/tray.sock",
              timeout=60,
          )
          main_pid = machine.succeed(
              "systemctl --user -M admin@ show gtk-status-bar -p MainPID --value"
          ).strip()
          print(f"gtk-status-bar MainPID={main_pid}")
          machine.wait_until_succeeds(
              "journalctl _SYSTEMD_USER_UNIT=gtk-status-bar.service --no-pager"
              " | grep -q 'Battery is at 73.0%'",
              timeout=60,
          )
          machine.wait_until_succeeds(
              "journalctl _SYSTEMD_USER_UNIT=gtk-status-bar.service --no-pager"
              " | grep -q 'Sent initial Bluetooth display: P80'",
              timeout=60,
          )

          # the bar's layer surface is mapped in Hyprland
          machine.wait_until_succeeds(
              "su - admin -c " + shlex.quote(
                  "env XDG_RUNTIME_DIR=/run/user/1000"
                  f" HYPRLAND_INSTANCE_SIGNATURE={his}"
                  " hyprctl layers | grep -qi 'gtk[-0-9a-z]*layer'"
              ),
              timeout=60,
          )
          save("hyprctl-layers.txt", admin("hyprctl layers"))
          save("hyprland-version.txt", admin("hyprctl version"))
          save(
              "uwsm-session-units.txt",
              machine.succeed(
                  "systemctl --user -M admin@ --no-pager --plain"
                  " --type=service --type=target | grep -E 'wayland|graphical|Hyprland|uwsm' || true"
              ),
          )

          machine.sleep(3)
          shot("01-bar-initial")
          initial_geometry = bar_geometry()
          assert initial_geometry[0:3] == (0, 0, 1920), initial_geometry
          save("bar-geometry.txt", f"initial={initial_geometry}\n")

          # --- Evidence 2: supervisor + listener logs ------------------------
          jrnl = machine.succeed(
              "journalctl _SYSTEMD_USER_UNIT=gtk-status-bar.service --no-pager -o short-iso"
          )
          save("gtk-status-bar-journal-initial.log", jrnl)
          for needle in [
              "Starting GTK status bar application",
              "Starting title event listener",
              "Starting workspace event listener",
              "Layer shell configured successfully",
              "Application activated successfully",
          ]:
              assert needle in jrnl, f"journal is missing: {needle}"

          # --- Evidence 3: workspace switching updates the widget ------------
          admin("hyprctl dispatch workspace 2")
          machine.sleep(2)
          shot("02-workspace-2")

          admin("hyprctl dispatch workspace 10")
          machine.sleep(2)
          shot("06-workspace-10")
          admin("hyprctl dispatch workspace 11")
          machine.sleep(2)
          shot("07-workspace-11-fallback")
          admin("hyprctl dispatch togglespecialworkspace evidence")
          machine.sleep(2)
          shot("08-special-workspace-named")
          admin("hyprctl dispatch togglespecialworkspace evidence")
          admin("hyprctl dispatch togglespecialworkspace")
          machine.sleep(2)
          shot("09-special-workspace-unnamed")
          admin("hyprctl dispatch togglespecialworkspace")
          for workspace in [1, 2, 3, 4, 5] * 4:
              admin(f"hyprctl dispatch workspace {workspace}")
          admin("hyprctl dispatch workspace 10")
          machine.sleep(2)
          shot("10-workspace-burst-final-10")
          admin("hyprctl dispatch workspace 2")

          # --- Evidence 4: window title lands in the bar ---------------------
          admin("hyprctl dispatch exec kitty")
          machine.wait_until_succeeds(
              "su - admin -c " + shlex.quote(
                  "env XDG_RUNTIME_DIR=/run/user/1000"
                  f" HYPRLAND_INSTANCE_SIGNATURE={his}"
                  " hyprctl clients -j | jq -e 'length >= 1'"
              ),
              timeout=60,
          )
          machine.sleep(3)
          shot("03-kitty-title")

          admin("hyprctl dispatch killactive")
          launch_title("hello")
          machine.sleep(2)
          shot("11-title-short")
          admin("hyprctl dispatch killactive")
          launch_title("A" * 64)
          machine.sleep(2)
          shot("12-title-exactly-64")
          admin("hyprctl dispatch killactive")
          launch_title("0123456789" * 8)
          machine.sleep(2)
          shot("13-title-cropped")
          admin("hyprctl dispatch killactive")
          launch_title(("\u754c\U0001F642" * 40))
          machine.sleep(2)
          shot("14-title-multibyte")
          title_geometry = bar_geometry()
          assert title_geometry == initial_geometry, (
              f"long multibyte title resized the bar: {title_geometry} != {initial_geometry}"
          )
          save(
              "bar-geometry.txt",
              f"initial={initial_geometry}\ntitle={title_geometry}\n",
          )
          admin("hyprctl dispatch killactive")

          # --- Evidence 5: keystroke injection (qemu) switches workspace -----
          machine.send_key("alt-1")
          machine.sleep(2)
          shot("04-sendkey-workspace-1")
          machine.send_key("alt-2")
          machine.sleep(2)

          # --- Evidence 6: focus changes and real mouse input ----------------
          admin("hyprctl dispatch workspace 2")
          machine.sleep(2)
          launch_title("Focus Left")
          left_address = __import__("json").loads(admin("hyprctl activewindow -j"))["address"]
          launch_title("Focus Right")
          right_address = __import__("json").loads(admin("hyprctl activewindow -j"))["address"]
          admin(f"hyprctl dispatch focuswindow address:{left_address}")
          machine.sleep(2)
          shot("15-focus-left")
          admin(f"hyprctl dispatch focuswindow address:{right_address}")
          machine.sleep(2)
          shot("16-focus-right")

          mouse_ok = True
          try:
              clients = admin("hyprctl clients -j")
              import json
              workspace_clients = [
                  client
                  for client in json.loads(clients)
                  if client["workspace"]["id"] == 2
              ]
              left = min(workspace_clients, key=lambda c: c["at"][0])
              cx = left["at"][0] + left["size"][0] // 2
              cy = left["at"][1] + left["size"][1] // 2
              shot("17-mouse-before-click")
              assert machine.qmp_client is not None
              machine.qmp_client.send(
                  "input-send-event",
                  cast(Any, {
                      "events": [
                          {"type": "abs", "data": {"axis": "x", "value": cx * 32767 // 1920}},
                          {"type": "abs", "data": {"axis": "y", "value": cy * 32767 // 480}},
                      ]
                  }),
              )
              machine.sleep(1)
              shot("18-mouse-positioned")
              machine.qmp_client.send(
                  "input-send-event",
                  cast(Any, {"events": [{"type": "btn", "data": {"button": "left", "down": True}}]}),
              )
              machine.qmp_client.send(
                  "input-send-event",
                  cast(Any, {"events": [{"type": "btn", "data": {"button": "left", "down": False}}]}),
              )
              machine.sleep(2)
              active = json.loads(admin("hyprctl activewindow -j"))
              assert active["address"] == left["address"], (
                  f"click did not focus left window: {active['address']} != {left['address']}"
              )
              shot("18-mouse-after-click")
          except Exception as e:
              mouse_ok = False
              print(f"mouse click evidence failed (non-fatal): {e}")

          # --- Evidence 7: UPower live updates and documented stale state -----
          machine.succeed("gtk-status-bar-mock-control battery 42 2")
          wait_log("Battery percentage changed to 42.0%")
          machine.sleep(2)
          shot("19-battery-42-discharging")
          machine.succeed("gtk-status-bar-mock-control battery 42 1")
          wait_log("Battery is charging (state: 1)")
          machine.sleep(2)
          shot("20-battery-charging-text-unchanged")
          machine.succeed("gtk-status-bar-mock-control battery 0 2")
          machine.sleep(2)
          shot("21-battery-0")
          machine.succeed("gtk-status-bar-mock-control battery 100 4")
          machine.sleep(2)
          shot("22-battery-100-full")
          machine.succeed("gtk-status-bar-mock-control battery 79.5 2")
          machine.sleep(2)
          shot("23-battery-rounding-80")
          machine.succeed("gtk-status-bar-mock-control battery-remove")
          machine.sleep(2)
          shot("24-battery-removed-stale")

          # --- Evidence 8: BlueZ initial scan, multiple devices, known bug ---
          machine.succeed("gtk-status-bar-mock-control bluez-extras")
          old_bar_pid = machine.succeed(
              "systemctl --user -M admin@ show gtk-status-bar -p MainPID --value"
          ).strip()
          machine.succeed("systemctl --user -M admin@ restart gtk-status-bar.service")
          machine.wait_until_succeeds(
              "test \"$(systemctl --user -M admin@ show gtk-status-bar -p MainPID --value)\""
              f" != {shlex.quote(old_bar_pid)}",
              timeout=60,
          )
          machine.sleep(4)
          shot("25-bluetooth-three-devices")
          machine.succeed("gtk-status-bar-mock-control bluez-percentage 65")
          machine.sleep(3)
          shot("26-bluetooth-properties-changed-known-bug")
          machine.succeed(
              "gtk-status-bar-mock-control bluez-remove"
              " /org/bluez/hci0/dev_AA_BB_CC_DD_EE_01"
          )
          machine.sleep(2)
          shot("27-bluetooth-pixel-removed")
          machine.succeed(
              "gtk-status-bar-mock-control bluez-remove"
              " /org/bluez/hci0/dev_AA_BB_CC_DD_EE_02"
          )
          machine.succeed(
              "gtk-status-bar-mock-control bluez-remove"
              " /org/bluez/hci0/dev_AA_BB_CC_DD_EE_03"
          )
          machine.sleep(2)
          shot("28-bluetooth-all-removed-hidden")

          # --- Evidence 9: real PipeWire/WirePlumber null sinks --------------
          alpha_module = admin(
              "pactl load-module module-null-sink"
              " sink_name=Alpha sink_properties=device.description=Alpha"
          ).strip()
          admin("pactl set-default-sink Alpha")
          admin("pactl set-sink-volume Alpha 50%")
          wait_log("Default sink ->", timeout=90)
          wait_log("GTK UI updated via ASYNC", timeout=90)
          machine.sleep(3)
          shot("29-volume-alpha-50")
          admin("pactl set-sink-volume Alpha 75%")
          machine.sleep(3)
          shot("30-volume-alpha-75")
          admin("pactl set-sink-mute Alpha 1")
          machine.sleep(3)
          shot("31-volume-muted")
          admin("pactl set-sink-mute Alpha 0")
          admin("pactl set-sink-volume Alpha 0%")
          machine.sleep(3)
          shot("32-volume-zero")
          admin("pactl set-sink-volume Alpha 100%")
          machine.sleep(3)
          shot("33-volume-100")
          bravo_module = admin(
              "pactl load-module module-null-sink"
              " sink_name=Bravo sink_properties=device.description=Bravo"
          ).strip()
          admin("pactl set-sink-volume Bravo 60%")
          admin("pactl set-default-sink Bravo")
          machine.sleep(4)
          shot("34-volume-default-bravo")
          admin(f"pactl unload-module {bravo_module}")
          machine.sleep(3)
          shot("35-volume-default-removed")
          admin(f"pactl unload-module {alpha_module}")

          # --- Evidence 10: service-owner recovery and systemd restart -------
          # Killing the system bus itself also tears down logind and therefore
          # the realistic UWSM session. Exercise service-owner disappearance
          # here; the report records the isolated monitor-reconnect case as a
          # VM limitation rather than pretending it passed.
          machine.succeed("systemctl stop dbusmock-seed.service")
          machine.succeed("systemctl restart dbusmock-upower.service dbusmock-bluez.service")
          machine.succeed("gtk-status-bar-mock-control recovery")
          machine.succeed("systemctl --user -M admin@ restart gtk-status-bar.service")
          wait_log("Battery is at 55.0%", timeout=60)
          machine.sleep(3)
          before_outage_pid = machine.succeed(
              "systemctl --user -M admin@ show gtk-status-bar -p MainPID --value"
          ).strip()
          machine.succeed("systemctl stop dbusmock-upower.service dbusmock-bluez.service")
          machine.sleep(3)
          shot("36-service-owners-missing-stale-state")
          machine.succeed("systemctl start dbusmock-upower.service dbusmock-bluez.service")
          machine.succeed("gtk-status-bar-mock-control post-recovery")
          machine.succeed("gtk-status-bar-mock-control battery 33 2")
          wait_log("Battery percentage changed to 33.0%", timeout=90)
          machine.sleep(3)
          shot("37-service-owners-recovered-new-state")
          assert machine.succeed(
              "systemctl --user -M admin@ show gtk-status-bar -p MainPID --value"
          ).strip() == before_outage_pid

          pre_kill_pid = machine.succeed(
              "systemctl --user -M admin@ show gtk-status-bar -p MainPID --value"
          ).strip()
          machine.succeed("systemctl --user -M admin@ kill -s SIGKILL gtk-status-bar.service")
          machine.wait_until_succeeds(
              "test \"$(systemctl --user -M admin@ show gtk-status-bar -p MainPID --value)\""
              f" != {shlex.quote(pre_kill_pid)}",
              timeout=60,
          )
          machine.sleep(4)
          shot("38-bar-systemd-restarted")

          # --- Evidence 11: clock advances across a minute -------------------
          minute_before = admin("date +%M").strip()
          shot("39-clock-before-minute")
          machine.wait_until_succeeds(
              f"test \"$(date +%M)\" != {shlex.quote(minute_before)}",
              timeout=70,
          )
          machine.sleep(2)
          shot("40-clock-after-minute")

          # --- Evidence 12: real StatusNotifierItem applications ------------
          admin("hyprctl dispatch exec -- fcitx5 -d --replace")
          admin("hyprctl dispatch exec -- blueman-applet")
          admin("hyprctl dispatch exec -- kdeconnect-indicator")
          admin(
              "hyprctl dispatch exec --"
              " claude-desktop --disable-gpu --password-store=basic"
          )
          machine.wait_until_succeeds(
              "test \"$(journalctl _SYSTEMD_USER_UNIT=gtk-status-bar.service"
              " --no-pager | grep -c 'Added system tray item')\" -ge 3",
              timeout=120,
          )
          machine.sleep(8)
          shot("41-tray-real-apps")
          tray_geometry = bar_geometry()
          assert tray_geometry == initial_geometry, (
              f"tray items resized the bar: {tray_geometry} != {initial_geometry}"
          )
          save(
              "tray-registered-items.txt",
              admin(
                  "busctl --user get-property org.kde.StatusNotifierWatcher"
                  " /StatusNotifierWatcher org.kde.StatusNotifierWatcher"
                  " RegisteredStatusNotifierItems",
                  check=False,
              )[1],
          )
          save(
              "tray-processes.txt",
              admin(
                  "ps -eo pid,comm,args | grep -E"
                  " 'fcitx5|blueman-applet|kdeconnect-indicator|claude-desktop'"
                  " | grep -v grep",
                  check=False,
              )[1],
          )

          # --- Evidence 13: trayctl socket and menu control -----------------
          tray_help = admin("trayctl --help")
          assert tray_help.startswith("Usage:\n"), tray_help
          socket_path = admin("trayctl socket-path").strip()
          assert socket_path == "/run/user/1000/gtk-status-bar/tray.sock", socket_path
          socket_mode = admin(
              "stat -c '%a %U %G %F' /run/user/1000/gtk-status-bar"
              " /run/user/1000/gtk-status-bar/tray.sock"
          )
          assert socket_mode.splitlines()[0].startswith("700 admin users directory")
          assert socket_mode.splitlines()[1].startswith("600 admin users socket")

          tray_response = json.loads(admin("trayctl --json list"))
          assert tray_response["ok"] is True, tray_response
          tray_items = tray_response["items"]
          assert len(tray_items) >= 3, tray_items
          save("trayctl-list.json", json.dumps(tray_response, indent=2) + "\n")
          save("trayctl-list.txt", admin("trayctl list"))
          save("trayctl-help.txt", tray_help)
          save("trayctl-socket.txt", socket_path + "\n" + socket_mode)

          menu_item = next(
              (
                  item for item in tray_items
                  if "fcitx" in (item["title"] + item["key"]).lower()
              ),
              tray_items[0],
          )
          menu_key = menu_item["key"]
          menu_title = menu_item["title"]
          menu_index = str(menu_item["index"])
          target_key = shlex.quote(menu_key)
          target_title = shlex.quote(menu_title)
          save(
              "trayctl-target.txt",
              f"index={menu_index}\ntitle={menu_title}\nkey={menu_key}\n",
          )

          # Exact key, exact title, and numeric index all resolve to the same
          # item. activate additionally proves menu-only items follow the same
          # open-menu path as a physical left click.
          admin(f"trayctl context-menu {target_key}")
          machine.wait_until_succeeds(
              "journalctl _SYSTEMD_USER_UNIT=gtk-status-bar.service --no-pager"
              " | grep -q 'Presenting tray menu'",
              timeout=30,
          )
          machine.sleep(2)
          shot("42-trayctl-context-menu-key")
          menu_geometry = bar_geometry()
          assert menu_geometry == initial_geometry, (
              f"open tray menu resized the bar: {menu_geometry} != {initial_geometry}"
          )

          admin(f"trayctl menu-next {target_key}")
          machine.sleep(2)
          shot("43-trayctl-menu-next")
          admin(f"trayctl menu-previous {target_key}")
          machine.sleep(2)
          shot("44-trayctl-menu-previous")
          admin("trayctl close-menus")
          machine.sleep(2)
          shot("45-trayctl-close-menus")

          if menu_title:
              admin(f"trayctl context-menu {target_title}")
              machine.sleep(1)
              admin("trayctl close-menus")
          admin(f"trayctl context-menu {shlex.quote(menu_index)}")
          machine.sleep(1)
          admin("trayctl close-menus")

          admin(f"trayctl activate {target_key}")
          machine.sleep(2)
          admin(f"trayctl menu-next {target_key}")
          shot("46-trayctl-menu-only-activate")
          admin(f"trayctl menu-activate {target_key}")
          machine.sleep(2)
          shot("47-trayctl-menu-activate")

          # menu-click accepts a dbusmenu entry ID. Real applications do not
          # publish those IDs through SNI, so probe the bounded integer range
          # while the menu is open and retain the first enabled entry as proof.
          admin(f"trayctl context-menu {target_key}")
          machine.sleep(2)
          clicked_id = None
          for entry_id in range(0, 256):
              status, output = admin(
                  f"trayctl menu-click {target_key} {entry_id}",
                  check=False,
              )
              if status == 0:
                  clicked_id = entry_id
                  break
          assert clicked_id is not None, "no enabled dbusmenu entry ID found in 0..255"
          save("trayctl-menu-click.txt", f"entry_id={clicked_id}\n")
          machine.sleep(2)
          shot("48-trayctl-menu-click")

          admin("fcitx5-remote -s mozc", check=False)
          admin(f"trayctl context-menu {target_key}")
          machine.sleep(2)
          shot("49-tray-fcitx-mozc")
          admin("trayctl close-menus")

          admin("pkill -TERM kdeconnect-ind", check=False)
          machine.sleep(4)
          shot("50-tray-item-removed")
          removed_geometry = bar_geometry()
          assert removed_geometry == initial_geometry, (
              f"tray item removal resized the bar: {removed_geometry} != {initial_geometry}"
          )
          save(
              "bar-geometry.txt",
              f"initial={initial_geometry}\ntitle={title_geometry}\n"
              f"tray={tray_geometry}\nmenu={menu_geometry}\n"
              f"removed={removed_geometry}\n",
          )

          # --- Final health evidence -----------------------------------------
          machine.succeed("systemctl --user -M admin@ is-active gtk-status-bar.service")
          n_restarts = machine.succeed(
              "systemctl --user -M admin@ show gtk-status-bar -p NRestarts --value"
          ).strip()
          end_pid = machine.succeed(
              "systemctl --user -M admin@ show gtk-status-bar -p MainPID --value"
          ).strip()
          assert end_pid != pre_kill_pid, "systemd did not replace the killed bar process"
          assert int(n_restarts) >= 1, "systemd did not record an automatic restart"

          save(
              "gtk-status-bar-journal-full.log",
              machine.succeed(
                  "journalctl _SYSTEMD_USER_UNIT=gtk-status-bar.service --no-pager -o short-iso"
              ),
          )
          save(
              "gtk-status-bar-status.txt",
              machine.succeed("systemctl --user -M admin@ status gtk-status-bar --no-pager -l || true"),
          )
          save("mouse-evidence.txt", f"mouse_ok={mouse_ok}\n")
          save(
              "bar-lifecycle.txt",
              f"initial_pid={main_pid}\npre_kill_pid={pre_kill_pid}\n"
              f"final_pid={end_pid}\nNRestarts={n_restarts}\n",
          )

          machine.shutdown()
        '';
      };
    };
}
