{ config, lib, pkgs, ... }:

let
  /*
  normalUsersSet = lib.filterAttrs (name: user: user.isNormalUser) config.users.users;
  normalUserNames = builtins.attrNames normalUsersSet;
  targetUser = lib.head normalUserNames;
  */

  /* one liner without user number check */
  # targetUser = lib.head (builtins.attrNames (lib.filterAttrs (n: u: u.isNormalUser) config.users.users));

  # 1. Find normal users
  normalUsersSet = lib.filterAttrs (n: u: u.isNormalUser) config.users.users;
  normalUserNames = builtins.attrNames normalUsersSet;

  # 2. Get the user count (like len() in Python)
  userCount = builtins.length normalUserNames;

  # 3. Logic check
  targetUser =
    if userCount == 1 then
      # If there is exactly 1, return that name
      builtins.head normalUserNames
    else
      # Otherwise, stop the build and throw an error!
      builtins.throw "ERROR: Exactly 1 normal user was expected, but ${toString userCount} were found.";

  targetUserHome = config.users.users."${targetUser}".home;
in
{
  services.restic.backups = {
    "${config.networking.hostName}-b2" = {
      user = "${targetUser}";
      initialize = true;
      repositoryFile = "/etc/nixos/restic/resticRepo";
      passwordFile = "/etc/nixos/restic/resticPasswd";
      environmentFile = "/etc/nixos/restic/resticEnv";
      backupPrepareCommand = ''
        ${pkgs.docker}/bin/docker run --rm --volumes-from wireguard:ro -v ${targetUserHome}/wireguard:/backup ubuntu \
          tar cvf /backup/backup.tar /config
      '';
      extraBackupArgs = [
        "--exclude-if-present=.exclude_from_backup"
        "--tag=systemd.timer"
        "--no-cache"
        "--no-scan"
        "--skip-if-unchanged"
      ];
      paths = [
        "/etc/nixos"
        "/home/nixos/wireguard"
      ];
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
        "--keep-yearly 3"
        "--keep-tag forever"
      ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        RandomizedOffsetSec = "5 days";
      };
    };

    "${config.networking.hostName}-local" = {
      user = "${targetUser}";
      initialize = true;
      repository = "${targetUserHome}/restic-backup";
      passwordFile = "/etc/nixos/restic/resticPasswd";
      environmentFile = "/etc/nixos/restic/resticEnv";
      backupPrepareCommand = ''
        [ -d ${targetUserHome}/restic-backup ] || mkdir --mode=700 --parents ${targetUserHome}/restic-backup
        ${pkgs.docker}/bin/docker run --rm --volumes-from wireguard:ro -v ${targetUserHome}/wireguard:/backup ubuntu \
          tar cvf /backup/backup.tar /config
      '';
      extraBackupArgs = [
        "--exclude-if-present=.exclude_from_backup"
        "--tag=systemd.timer"
        "--no-cache"
        "--no-scan"
        "--skip-if-unchanged"
      ];
      paths = [
        "/etc/nixos"
        "/home/nixos/wireguard"
      ];
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
        "--keep-yearly 3"
        "--keep-tag forever"
      ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        RandomizedOffsetSec = "5 days";
      };
    };

    # test service for systemd credentials
    # services.restic.backups.<name>.createWrapper not working with systemd credentials
    test = {
      user = "${targetUser}";
      initialize = true;
      repository = "${targetUserHome}/test";
      environmentFile = "";
      backupPrepareCommand = ''
        [ -d ${targetUserHome}/test ] || mkdir --mode=700 --parents --verbose ${targetUserHome}/test
        printf "SetCredentialEncrypted=secretPasswd:<encrypted-password> ==> $(${pkgs.systemd}/bin/systemd-creds --user cat secretPasswd)\n"
        printf "RESTIC_PASSWORD_FILE=%%d/secretPasswd ==> $(printenv RESTIC_PASSWORD_FILE)\n"
        printf "$(printenv RESTIC_PASSWORD_FILE) ==> $(cat $(printenv RESTIC_PASSWORD_FILE))"
      '';
      backupCleanupCommand = ''
        rm -rf ${targetUserHome}/test/*
        [ ! -d ${targetUserHome}/test ] || rmdir --verbose ${targetUserHome}/test
      '';
      extraBackupArgs = [
        "--exclude-if-present=.exclude_from_backup"
        "--tag=test"
        "--no-cache"
        "--no-scan"
        "--skip-if-unchanged"
        "--verbose"
        "--dry-run"
      ];
      paths = [
        "/etc/nixos"
      ];
    };
  };
  /*
  systemd.units."restic-backups-${config.networking.hostName}-local" = {
    overrideStrategy = "asDropin";
    text = ''
      [Service]
      Environment="RESTIC_CACHE_DIR="
    '';
  };
  */
  # Disable cache: https://github.com/NixOS/nixpkgs/issues/475016
  systemd.services = (lib.genAttrs [
    "restic-backups-${config.networking.hostName}-local"
    "restic-backups-${config.networking.hostName}-b2"
  ] (_: {
    environment = { RESTIC_CACHE_DIR = lib.mkForce ""; };
    serviceConfig = { CacheDirectory = lib.mkForce ""; };
  })) // {
    "restic-backups-test" = {
      enable = false;
      environment = {
        RESTIC_CACHE_DIR = lib.mkForce "";
        RESTIC_REPOSITORY = "${targetUserHome}/test";
        RESTIC_PASSWORD_FILE = lib.mkForce "%d/secretPasswd";
        B2_ACCOUNT_ID = "%d/b2ID";
        B2_ACCOUNT_KEY = "%d/b2KEY";
      };
      serviceConfig = {
        CacheDirectory = lib.mkForce "";
        # echo -n "password" | sudo systemd-creds encrypt --with-key=host --name=secretPasswd - - | tr -d '\n'
        # sudo systemd-run --verbose --pipe --wait --property SetCredentialEncrypted="secretPasswd:<encrypted-password>" --property User=<your-user-name> systemd-creds cat secretPasswd
        SetCredentialEncrypted = [
          "secretPasswd:Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAAA/INMTqEIVGof0eAYAAAAA3fiNhkvwWWsCmsODTa0+fvhrGHotAO7wjAwOUL8QTQCO9NWe2fONzcukaGZJJGzJ/zmNgY6Y/tg="
          "resticPasswd:Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAAB27OdAkiWZOg+S7ZkAAAAAIKF9bG1WtHlOqldkqCgswI49ZLdXpqLvEiRAocBmvzGq1ztyrjzKHWmE4Jv5uVGhacB5sbmhqwAigJhAaEo="
          "b2ID:Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAADvtc5O2S4WjfLP/bAAAAAA0at3e7sbkt2G/ZXaPNySdz3c0Cv8mRqkvwyJHOQINGXxsUnjkM7eUnZx3fS5SVLNHLDyM1r7cEG7Xi1SWZFooVE="
          "b2KEY:Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAABgzQdCYFtHCyXppAcAAAAAcPZzZ8f1iAN4dypbhYTQCADHU0Th+0X46Fn1kwfXb3VWKMChj3IjRjMFlccNyCyvqftm/ud/Z5JjQUjjGjNnD78DHG8OzUc4H2nMMG/W1w=="
        ];
      };
    };
  };

  environment.systemPackages = [
    (pkgs.writers.writeBashBin "restic-${config.networking.hostName}-local-with_systemd_creds"
    # $ is escaped by prefixing it with two single quotes ('')
    # https://nix.dev/manual/nix/latest/language/string-literals
    ''
      ${pkgs.systemd}/bin/systemd-run --quiet --user --wait --pipe \
        --property "LoadCredential=resticPasswd:/etc/nixos/restic/resticPasswd" -- \
        ${pkgs.bash}/bin/bash -c \
          '${pkgs.restic}/bin/restic \
          --repo ${targetUserHome}/restic-backup \
          --password-file "''${CREDENTIALS_DIRECTORY}/resticPasswd" "''$@"' -- "''$@"
    '')
    (pkgs.writers.writeBashBin "restic-${config.networking.hostName}-local-alt" ''
      ${pkgs.restic}/bin/restic --repo ${targetUserHome}/restic-backup \
        --password-file ${config.services.restic.backups."${config.networking.hostName}-local".passwordFile} \
        "$@"
    '')
    (pkgs.writers.writeBashBin "restic-${config.networking.hostName}-local-alt-mount" ''
      mountdir=$(mktemp -p "$XDG_RUNTIME_DIR" -d "restic-mount-XXXXXXX")
      trap clean EXIT
      clean() {
        rm -r "$mountdir"
      }
      ${pkgs.restic}/bin/restic --repo ${targetUserHome}/restic-backup \
        --password-file ${config.services.restic.backups."${config.networking.hostName}-local".passwordFile} \
        mount "$mountdir"
    '')
  ];
}
