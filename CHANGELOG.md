# Changelog

All notable changes to obc40-screensaver. Versions follow [semantic versioning](https://semver.org/).

## 0.2.0

- The power key no longer shuts the board down. Before, elogind could still power the board off even with the XFCE power button set to *do nothing*. New `install.sh --system` (as root) installs an elogind setting that ignores the key (`HandlePowerKey=ignore`), and a udev rule that lets the `video` group change the backlight. Both apply at once, without a reboot. Turn the board off from the home screen.

## 0.1.0

First version.

- The power key on the back of the OBC40 shows and hides a fullscreen screensaver. A touch on the screen also hides it, and that touch does not reach the windows below.
- 3D pipes that grow in perspective, with correct depth order, and the clock and date in front of them.
- Backlight dimmed while the screensaver is shown (`--dim N`, default 5%), then restored.
- `install.sh`: installs for the current user, starts it at every XFCE login, and sets the XFCE power button action to *do nothing*. Options: `--dim N`, `--no-autostart`, `--uninstall`.
