{ config, pkgs, lib, ... }:
{
  boot.initrd.availableKernelModules = [ "ata_piix" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/fd3cc427-122e-444c-a8b5-91f1339fe429";
      fsType = "ext4";
    };
  fileSystems."/vagrant" =
    { device = "vagrant";
      fsType = "vboxsf";
      options = [ "rw" "nodev" "relatime" "iocharset=utf8" "uid=1000" "gid=999" "_netdev"];
    };

  virtualisation.virtualbox.guest.enable = true;
  virtualisation.docker.enable = true;
  virtualisation.docker.daemon.settings = {
    features.buildkit = true;
  };

  boot = {
    # Use the GRUB 2 boot loader
    loader.grub.enable = true;
    loader.grub.version = 2;
    loader.grub.device   = "/dev/sda";
    supportedFilesystems = ["nfs4"];
  };

  environment.systemPackages = with pkgs; [
    kube3d
    kubectl
  ];
  security.sudo.configFile =
    ''
    Defaults:root,%wheel env_keep+=LOCALE_ARCHIVE
    Defaults:root,%wheel env_keep+=NIX_PATH
    Defaults lecture = never
    '';
  security.sudo.wheelNeedsPassword = false;
  services = {
    openssh.enable    = true;
  };
  nix.settings.trusted-users = [ "root" "@wheel" ];
  users = {
    mutableUsers = false;
    groups.vagrant = {};
    users.vagrant = {
      description     = "Vagrant User";
      group           = "vagrant";
      extraGroups     = [ "users" "wheel" "vboxsf" "docker" ];
      password        = "vagrant";
      home            = "/home/vagrant";
      isNormalUser    = true;
      createHome      = true;
      useDefaultShell = true;
    };
  };
  services.netdata = {
    enable = true;
    config = {
      web = {
        "bind to" = "*:19999";
      };
    };
  };
  networking.hostName = "k3d-server";
  networking.interfaces = {
    enp0s8.ipv4.addresses = [{
      address = "192.168.57.51";
      prefixLength = 24;
    }];
  };
  networking.firewall.package = pkgs.iptables-legacy;
  networking.firewall.allowedTCPPorts = [
    6443
    19999
  ];
}