{ ... }:
{
  hardware.deviceTree = {
    enable = true;
    filter = "bcm2837-rpi-3-b.dtb";
    overlays = [
      {
        name = "disable-wifi";
        dtsText = ''
          /dts-v1/;
          /plugin/; 
          / {
            compatible = "raspberrypi,3-model-b", "brcm,bcm2837";

            /* Wi-Fi: RPi3B+'da Wi-Fi genellikle mmc1 (SDIO) üzerindedir */
            /* aliase mmc1 = &mmcnr */
            fragment@0 {
              target = <&mmcnr>;
              __overlay__ { status = "disabled"; };
            };
          };
        '';
      }
    ];
  };
}
