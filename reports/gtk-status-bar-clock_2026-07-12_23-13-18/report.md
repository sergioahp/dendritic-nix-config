# GTK status bar reactive clock evidence

Date: 2026-07-12

The VM test set the guest wall clock to `2030-01-02 03:04:58.200 UTC` and
observed the status bar at `3:04 AM`. It then observed `3:05 AM` immediately
after the minute boundary. The test next jumped the wall clock forward to
`2030-01-02 11:58:30 UTC`; the bar realigned and displayed `11:58 AM` within
the one-second guard interval.

Evidence:

- `clock-before-minute.png`: label before the natural minute boundary.
- `clock-after-minute.png`: label after the natural minute boundary.
- `clock-after-jump.png`: label after a discontinuous wall-clock change.

The bar package's unit and integration tests passed in the VM build. The
network-state and clock sequences also passed. The monolithic VM check later
failed at the pre-existing, unrelated `Closing tray menu from keyboard`
timeout; this does not affect the recorded clock assertions or screenshots.
