{ ... }:
{
  hardware.deviceTree = {
    enable = true;
    filter = "bcm2837-rpi-3-b.dtb";
    overlays = [
      {
        name = "disable-v4l2-codecs";
        dtsText = ''
          /dts-v1/;
          /plugin/;

          /* V4L2, Codec ve Kamera Arayüzlerini Kapatma */

          / {
            compatible = "raspberrypi,3-model-b", "brcm,bcm2837";

            /* 1. CSI (Camera Serial Interface) Donanımını Kapat */
            /* V4L2 modülleri genellikle kamera arayüzü taramasıyla tetiklenir */
            fragment@0 {
              target = <&csi1>;
              __overlay__ {
                status = "disabled";
              };
            };

            /* 2. VCHIQ (VideoCore Host Interface Queue) - DİKKAT */
            /* Bu, ARM işlemci ile VideoCore GPU arasındaki ana iletişim köprüsüdür. */
            /* bcm2835_codec, bcm2835_v4l2, bcm2835_audio bunun üzerinden çalışır. */
            /* Bunu kapatmak tüm multimedya özelliklerini donanım seviyesinde keser. */
            fragment@1 {
              target = <&vchiq>;
              __overlay__ {
                status = "disabled";
              };
            };
          };
        '';
      }
    ];
  };
}
