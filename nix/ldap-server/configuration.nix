{ config, lib, pkgs, modulesPath, ... }:
{
  nixpkgs.system = "x86_64-linux";

  boot.initrd.availableKernelModules = [ "ata_piix" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

  swapDevices = [ ];
  boot = {
    # Use the GRUB 2 boot loader
    loader.grub.enable = true;
    loader.grub.version = 2;
    loader.grub.device   = "/dev/sda";
    supportedFilesystems = ["nfs4"];
  };

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
    mutableUsers = true;
    groups.vagrant = {};
    users.vagrant = {
      description     = "Vagrant User";
      group           = "vagrant";
      extraGroups     = [ "users" "wheel" "vboxsf" ];
      password        = "vagrant";
      home            = "/home/vagrant";
      isNormalUser    = true;
      createHome      = true;
      useDefaultShell = true;
    };
  };

    # Enable guest additions.
  virtualisation.virtualbox.guest.enable = true;

  services.openldap = {
    enable = true;
    urlList = [ "ldap:///" ];

    settings = {
      attrs.olcLogLevel = [ "stats" ];
      children = {
        "cn=schema".includes = [
            "${pkgs.openldap}/etc/schema/core.ldif"
            "${pkgs.openldap}/etc/schema/cosine.ldif"
            "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
            "${pkgs.openldap}/etc/schema/nis.ldif"
        ];
        "olcDatabase={-1}frontend" = {
          attrs = {
            objectClass = "olcDatabaseConfig";
            olcDatabase = "{-1}frontend";
          };
        };
        "olcDatabase={0}config" = {
          attrs = {
            objectClass = "olcDatabaseConfig";
            olcDatabase = "{0}config";
          };
        };
        "olcDatabase={1}mdb" = {
          attrs = {
            objectClass = [ "olcDatabaseConfig" "olcMdbConfig" ];
            olcDatabase = "{1}mdb";
            olcDbDirectory = "/var/lib/openldap/db/";
            olcDbIndex = [
              "objectClass eq"
              "cn pres,eq"
              "uid pres,eq"
              "sn pres,eq,subany"
            ];
            olcSuffix = "dc=nixos,dc=org";
          };
        };
      };
    };
    declarativeContents."dc=nixos,dc=org" = ''
      dn: dc=nixos,dc=org
      objectclass: domain
      dc: nixos

      dn: ou=People,dc=nixos,dc=org
      objectclass: top
      objectclass: organizationalUnit
      ou: People

      dn: ou=Service Accounts,dc=nixos,dc=org
      objectclass: top
      objectclass: organizationalUnit
      ou: Service Accounts

      dn: ou=Roles,dc=nixos,dc=org
      objectclass: top
      objectclass: organizationalUnit
      ou: Roles

      dn: uid=sa-client-login,ou=Service Accounts,dc=nixos,dc=org
      objectclass: top
      objectclass: organizationalPerson
      objectclass: person
      objectclass: inetOrgPerson
      objectClass: posixAccount
      objectClass: shadowAccount
      uid: sa-client-login
      cn: sa-client-login
      sn: sa-client-login
      displayName: Client Login Service Account
      mail: sa-client-login@localhost
      userPassword: sa-client-login
      loginShell: /bin/false
      homeDirectory: /home/sa-client-login
      description: Client Login Service Account
      uidNumber: 20000
      gidNumber: 20000

      dn: uid=admin,ou=People,dc=nixos,dc=org
      objectclass: top
      objectclass: organizationalPerson
      objectclass: person
      objectclass: inetOrgPerson
      objectClass: posixAccount
      objectClass: shadowAccount
      uid: admin
      cn: admin
      sn: admin
      displayName: Administrator
      mail: admin@localhost
      userPassword: {CRYPT}SLoYkW0C5trws
      loginShell: /bin/bash
      homeDirectory: /home/admin
      description: Administrator
      uidNumber: 2000
      gidNumber: 1500

      dn: cn=Service Accounts,ou=Roles,dc=nixos,dc=org
      objectclass: top
      objectClass: posixGroup
      cn: Service Accounts
      description: Service Account Group
      gidNumber: 20000
      memberUid: sa-client-login

      dn: cn=consoleAdmin,ou=Roles,dc=nixos,dc=org
      objectclass: top
      objectclass: posixGroup
      cn: consoleAdmin
      description: consoleAdmin
      gidNumber: 20001
      memberUid: sa-client-login
      memberUid: admin

      dn: cn=admins,ou=Roles,dc=nixos,dc=org
      objectclass: top
      objectClass: posixGroup
      cn: admins
      description: Administrator Group
      gidNumber: 1500
      memberUid: admin
      memberUid: sa-client-login
    '';
  };

  users.ldap = {
    enable      = true;
    server      = "ldap://localhost";
    base        = "dc=nixos,dc=org";
    extraConfig = ''
      ldap_version 3
      pam_password crypt
    '';
  };
  security.pam.services."login".makeHomeDir = true;
  security.pam.services."su".makeHomeDir = true;
  security.pam.services."sudo" = {
    makeHomeDir = true;
    text = lib.mkDefault (
      lib.mkBefore ''
        auth required pam_listfile.so \
          item=group sense=allow onerr=fail file=/etc/allowed_groups
      ''
    );
  };
  security.pam.services."sshd" = {
    makeHomeDir = true;
    text = lib.mkDefault (
      lib.mkBefore ''
        auth required pam_listfile.so \
          item=group sense=allow onerr=fail file=/etc/allowed_groups
      ''
    );
  };

  security.sudo.extraRules = [{
    groups    = [ "admins" ]; 
    commands  = [ { command = "ALL"; options = [ "SETENV" "NOPASSWD" ]; } ]; 
  }];

  environment.etc.allowed_groups = {
    text = "admins";
    mode = "0444";
  };

  systemd.tmpfiles.rules = [
    "L /bin/bash - - - - /run/current-system/sw/bin/bash"
    "L /bin/zsh  - - - - /run/current-system/sw/bin/zsh"
    "L /bin/fish - - - - /run/current-system/sw/bin/fish"
  ];

  networking.interfaces.enp0s3.useDHCP = true;
  networking.interfaces.enp0s8.ipv4.addresses = [{ address = "192.168.57.10"; prefixLength = 24; }];

  networking.firewall.enable = false;

  boot.kernel.sysctl."net.ipv4.ip_forward" = true;
}
