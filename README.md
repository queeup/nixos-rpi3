# Headless nixos server for Raspberry Pi 3

Check `overlays/` directory for how to disable most of the hardwares.

```bash
$ tail -n +1 /proc/device-tree/soc/{dsi@*,fb,gpu,hdmi@*,mmcnr@*,pixelvalve@*,sound,v3d@*,vec@*}/status
==> /proc/device-tree/soc/dsi@7e209000/status <==
disabled
==> /proc/device-tree/soc/dsi@7e700000/status <==
disabled
==> /proc/device-tree/soc/fb/status <==
disabled
==> /proc/device-tree/soc/gpu/status <==
disabled
==> /proc/device-tree/soc/hdmi@7e902000/status <==
disabled
==> /proc/device-tree/soc/mmcnr@7e300000/status <==
disabled
==> /proc/device-tree/soc/pixelvalve@7e206000/status <==
disabled
==> /proc/device-tree/soc/pixelvalve@7e207000/status <==
disabled
==> /proc/device-tree/soc/pixelvalve@7e807000/status <==
disabled
==> /proc/device-tree/soc/sound/status <==
disabled
==> /proc/device-tree/soc/v3d@7ec00000/status <==
disabled
==> /proc/device-tree/soc/vec@7e806000/status <==
disabled
```
