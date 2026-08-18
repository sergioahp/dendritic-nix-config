{ ... }: {
  # Bluetooth, split the way the radio and the UI actually split.
  #
  # The radio is a hardware fact, so it is a capability a machine imports (like
  # xremap or kdeconnect) rather than something the graphical tier assumes:
  # nixd has no bluetooth adapter worth pairing from, the test VM has none at
  # all, and enabling bluez there would be a daemon running for no device.
  flake.nixosModules.bluetooth = {
    # bluez plus bluetooth.service. powerOnBoot is left at its default (on),
    # since a laptop that pairs a headset wants the adapter up before anyone
    # thinks to ask for it.
    hardware.bluetooth.enable = true;
  };

  # blueman is the applet: a tray icon and a D-Bus service that only mean
  # something inside a graphical session, so it lands on the graphical tier --
  # but only when the machine actually brought a radio. That keeps the pairing
  # UI out of the headless tier of the very same machine (msi and
  # msi-graphical are built from one machine module) without either half
  # having to name the other.
  flake.nixosModules.graphical = { config, lib, ... }: {
    services.blueman.enable = lib.mkIf config.hardware.bluetooth.enable true;
  };
}
