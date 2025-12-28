{ ... }:
{
  hardware.deviceTree = {
    enable = true;
    filter = "bcm2837-rpi-3-b.dtb";
    overlays = [
      {
        name = "disable-gpu";
        dtsText = ''
          /dts-v1/;
          /plugin/;

          /* GPU/Video (VC4 ve V3D) Kapatma */

          / {
            compatible = "raspberrypi,3-model-b", "brcm,bcm2837";

            /* V3D (3D Hızlandırma Birimi) donanımını kapat */
            fragment@0 {
              target = <&v3d>;
              __overlay__ {
                status = "disabled";
              };
            };

            /* VC4 (VideoCore 4 DRM Sürücüsü) sanal aygıtını kapat */
            fragment@1 {
              target = <&vc4>;
              __overlay__ {
                status = "disabled";
              };
            };

            /* PixelValve (Görüntü tarama/oluşturma hattı) birimlerini kapat */
            fragment@2 {
              target = <&pixelvalve0>;
              __overlay__ { status = "disabled"; };
            };
            fragment@3 {
              target = <&pixelvalve1>;
              __overlay__ { status = "disabled"; };
            };
            fragment@4 {
              target = <&pixelvalve2>;
              __overlay__ { status = "disabled"; };
            };

            /* HVS (Hardware Video Scaler) birimini kapat */
            fragment@5 {
              target = <&hvs>;
              __overlay__ { status = "disabled"; };
            };

            /* FB (Framebuffer) birimini kapat */
            fragment@6 {
              target = <&fb>;
              __overlay__ { status = "disabled"; };
            };
          };
        '';
      }
    ];
  };
}
