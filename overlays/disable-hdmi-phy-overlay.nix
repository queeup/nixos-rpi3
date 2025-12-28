{ ... }:
{
  hardware.deviceTree = {
    enable = true;
    filter = "bcm2837-rpi-3-b.dtb";
    overlays = [
      {
        name = "disable-hdmi-phy";
        dtsText = ''
          /dts-v1/;
          /plugin/;

          /* HDMI Fiziksel Arayüzünü Kapatma (Güç Tasarrufu Odaklı) */

          / {
            compatible = "raspberrypi,3-model-b", "brcm,bcm2837";

            /* HDMI Kontrolcüsünü Kapat */
            fragment@0 {
              target = <&hdmi>;
              __overlay__ {
                status = "disabled";
                /* İsteğe bağlı: Güç alanlarını da kapatmayı deneyebiliriz */
                power-domains = <&power 5>; /* RPI_POWER_DOMAIN_HDMI = 5 genellikle HDMI güç alanıdır */
              };
            };
          };
        '';
      }
    ];
  };
}
