{ pkgs, config, ... }:

let
  unstable = import
    (builtins.fetchTarball {
      url = https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz;
    })
    # reuse the current configuration
    { config = config.nixpkgs.config; };
in

{
  environment = {
    systemPackages = with pkgs; [
      unstable.tailscale
      unstable.atuin
      unstable.bash-preexec
      # unstable.blesh
    ];
  };
  programs.bash = {
    interactiveShellInit = ''
      source ${unstable.bash-preexec}/share/bash/bash-preexec.sh
      #source ${unstable.blesh}/share/blesh/ble.sh
      eval "$(${unstable.atuin}/bin/atuin init bash)"
    '';
  };
  services.tailscale.package = unstable.tailscale;
  # services.atuin.package = unstable.atuin;
}
