{ lib, pkgs, ... }:

let
  user = "nixos";
  /* 
   * Create hashed password
   * echo "password" | mkpasswd -s
   */
  hashedPassword = "$y$j9T$ISb200okmPZ.X45UqyIk41$TqOrxYgB5u/0NO96VLRFVzWZekBNgHTNDi7WUkJOP74";
  SSID = "mywifi";
  SSIDpassword = "mypassword";
  interface = "wlan0";
  hostname = "nixos-rpi3";
in
{
  imports =
    [
      #<nixos-hardware/raspberry-pi/3>
      ## ls /nix/store/*/nixos/nixos/modules/profiles/
      ## https://nlewo.github.io/nixos-manual-sphinx/configuration/profiles.xml.html
      <nixpkgs/nixos/modules/profiles/minimal.nix>
      #<nixpkgs/nixos/modules/profiles/hardened.nix>
      /* 
       * Check hardware status:
       * tail -n +1 /proc/device-tree/soc/{dsi@*,fb,gpu,hdmi@*,mmcnr@*,pixelvalve@*,sound,v3d@*,vec@*}/status
       */
      ./overlays/disable-bt-overlay.nix
      ./overlays/disable-gpu-overlay.nix
      ./overlays/disable-hdmi-phy-overlay.nix
      ./overlays/disable-v4l2-codecs-overlay.nix
      ./overlays/disable-wifi-overlay.nix
      #./overlays/set-cma-size-overlay.nix  # use boot.kernelParams (cmdline) instead
      ./restic-backups.nix
    ];

  /*
   * fix the following error :
   * modprobe: FATAL: Module ahci not found in directory
   * https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1350599022
   */
  nixpkgs.overlays = [
    (_final: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  hardware = {
    bluetooth = {
      enable = lib.mkForce false;
      powerOnBoot = lib.mkForce false;
    };
    enableAllHardware = lib.mkForce false;
    enableRedistributableFirmware = true;
    /*
    deviceTree = {
      enable = true;
      filter = "bcm2837-rpi-3-b.dtb";
      ## https://github.com/raspberrypi/linux/tree/rpi-6.12.y/arch/arm/boot/dts/overlays
      ## https://github.com/raspberrypi/linux/blob/rpi-6.12.y/arch/arm/boot/dts/broadcom/bcm2710-rpi-3-b.dts
      ## https://github.com/raspberrypi/linux/blob/rpi-6.12.y/arch/arm/boot/dts/broadcom/bcm2837-rpi-3-b.dts
      overlays = [
        #{
        #  name = "disable-bt";
        #  dtsFile = ./dts/disable-bt.dts;
        #}
      ];
    };
    */
  };

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi3;
    kernelParams = [
      "cma=16M"
      #"dtparam=audio=off"
      #"video=HDMI-A-1:d"
      "logo.nologo"
      "audit=0"
      #"console=ttyS0,115200n8"
      #"console=tty0"
    ];
    initrd.systemd.tpm2.enable = false;
    initrd.availableKernelModules = [ "usbhid" "usb-storage" ];
    blacklistedKernelModules = [ ];
    # avoid building zfs
    supportedFilesystems = lib.mkForce [ "vfat" "ext4" ];
    loader = {
      grub.enable = lib.mkDefault false;
      timeout = 0;
      generic-extlinux-compatible = {
        enable = lib.mkDefault true;
        configurationLimit = 5;
      };
    };
    #tmp.useTmpfs = true;
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 60;
    #priority = 20;
  };

  swapDevices = [{
    device = "/swapfile";
    size = 4 * 1024; # 4GB
  }];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
    #"/boot/firmware" = {
    #  device = "/dev/disk/by-label/FIRMWARE";
    #  fsType = "vfat";
    #};
  };

  networking = {
    hostName = hostname;
    #usePredictableInterfaceNames = false;
    wireless = {
      enable = false;
      networks."${SSID}".psk = SSIDpassword;
      interfaces = [ interface ];
    };
    interfaces.eth0 = {
      useDHCP = true;
      #ipv4.addresses = [{
      #  address = "192.168.1.100";
      #  prefixLength = 24;
      #}];
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ 31820 ];
    };
  };

  environment = {
    #systemPackages = with pkgs; [ vim ];
    etc = {
      "systemd/journald.conf.d/99-storage.conf".text = ''
        [Journal]
        Storage=volatile
        RuntimeMaxUse=100M
        RuntimeKeepFree=20M
      '';
    };
    variables = {
      HISTCONTROL = "erasedups:ignorespace";
      HISTSIZE = lib.mkDefault "-1";
      HISTFILESIZE = lib.mkDefault "-1";
      HISTTIMEFORMAT = lib.mkDefault "%Y-%m-%d %T ";
      # Save each command in history as soon as it is executed
      PROMPT_COMMAND= "history -a;$PROMPT_COMMAND";
    };
  };

  /*
  # profiles/minimal.nix takes care of this.
  documentation = {
    enable = false;
    man.enable = false;
    doc.enable = false;
    info.enable = false;
    nixos.enable = false;
  };
  */

  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    startWhenNeeded = true;
    authorizedKeysInHomedir = false;  # Do not trust SSH keys in ~/.ssh/authorized_keys.
    extraConfig = ''
      Match Address 192.168.1.0/24
          PubkeyAuthentication yes
          AllowUsers nixos
    '';
    settings = {
      PasswordAuthentication = false;
      PubkeyAuthentication = false;
      PermitRootLogin = "no";
      #AllowUsers = [ "nixos" ];
      #PrintMotd = true;
    };
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  services.irqbalance.enable = true;

  users = {
    mutableUsers = false;
    users."${user}" = {
      isNormalUser = true;
      initialHashedPassword = hashedPassword;
      extraGroups = [ "wheel" "docker" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA0iiagxeuPpQn4Wgz6h1If/hOMmnzwN9zzxC2LXhpCh nixos@nixos-zgz"
      ];
    };
  };

  time.timeZone = "Europe/Madrid";

  /*
  console = {
    keyMap = "trq";
  };
  */

  virtualisation = {
    docker = {
      enable = true;
      liveRestore = false;  # https://github.com/NixOS/nixpkgs/issues/182916
    };
  };

  nix = {
    settings.auto-optimise-store = false;  # Avoiding some heavy IO
    settings.download-buffer-size = 134217728; # 128 MiB
    gc.automatic = true;
    gc.dates = "weekly";
    gc.options = "--delete-older-than 14d";
  };

  system.stateVersion = "25.11";
}
