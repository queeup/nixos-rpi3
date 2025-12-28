{ ... }:
{
  hardware.deviceTree = {
    enable = true;
    filter = "bcm2837-rpi-3-b.dtb";
    overlays = [
      {
        name = "set-cma-size";
        dtsText = ''
          /dts-v1/;
          /plugin/;

          / {
            compatible = "raspberrypi,3-model-b", "brcm,bcm2837";

            fragment@0 {
              target = <&cma>;
              frag0: __overlay__ {
                /*
                 * The default size when using this overlay is 256 MB
                 * and should be kept as is for backwards
                 * compatibility.
                 */
                size = <0x1000000>; /* 16MB */
              };
            };

            __overrides__ {
              cma-512 = <&frag0>,"size:0=",<0x20000000>;
              cma-448 = <&frag0>,"size:0=",<0x1c000000>;
              cma-384 = <&frag0>,"size:0=",<0x18000000>;
              cma-320 = <&frag0>,"size:0=",<0x14000000>;
              cma-256 = <&frag0>,"size:0=",<0x10000000>;
              cma-192 = <&frag0>,"size:0=",<0xC000000>;
              cma-128 = <&frag0>,"size:0=",<0x8000000>;
              cma-96  = <&frag0>,"size:0=",<0x6000000>;
              cma-64  = <&frag0>,"size:0=",<0x4000000>;
              cma-size = <&frag0>,"size:0"; /* in bytes, 4MB aligned */
              cma-default = <0>,"-0";
            };
          };
        '';
      }
    ];
  };
}
