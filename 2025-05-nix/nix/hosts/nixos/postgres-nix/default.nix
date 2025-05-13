{ config, inputs, pkgs, name, lib, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./../../common/nixos-common.nix
      ./../../common/common-packages.nix
    ];

  # Boot configuration
  boot.loader = {
    systemd-boot.enable = false;
    efi.canTouchEfiVariables = false;
    grub = {
      enable = true;
      device = "/dev/vda";  # Use the main disk device
      useOSProber = true;
      forceInstall = true;  # Force install despite blocklist warnings
    };
  };

  # Add this to ensure proper partition detection
  boot.supportedFilesystems = [ "ext4" ];

  # Network configuration
  networking = {
    firewall = {
      enable = true;
      # Allow tailscale traffic
      trustedInterfaces = [ "tailscale0" ];
      # PostgreSQL port is only accessible via Tailscale, no need to open public ports
      # Allow the tailscale UDP port
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
    hostName = "postgres-nix";
    # Use DHCP as requested
    useDHCP = true;
  };

  # System localization
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver = {
    enable = false;
  };

  # SSH configuration
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
    settings.PermitRootLogin = "yes";
  };
  
  services.qemuGuest.enable = true;
  
  # PostgreSQL configuration for production
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    enableTCPIP = true;
    # Allow connections from localhost and Tailscale network
    authentication = pkgs.lib.mkOverride 10 ''
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      local   all             all                                     peer
      host    all             all             127.0.0.1/32            scram-sha-256
      host    all             all             ::1/128                 scram-sha-256
      host    all             all             100.64.0.0/10           scram-sha-256
    '';
    # Production settings
    settings = {
      max_connections = 100;
      shared_buffers = "1GB";
      effective_cache_size = "3GB";
      maintenance_work_mem = "256MB";
      checkpoint_completion_target = 0.9;
      wal_buffers = "16MB";
      default_statistics_target = 100;
      random_page_cost = 1.1;
      effective_io_concurrency = 200;
      work_mem = "10MB";
      min_wal_size = "1GB";
      max_wal_size = "4GB";
    };
    # Initialize with postgres superuser and create a database
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE ROLE ryan WITH LOGIN PASSWORD 'CHANGE_THIS_PASSWORD' CREATEDB SUPERUSER;
      CREATE DATABASE app_database;
      GRANT ALL PRIVILEGES ON DATABASE app_database TO ryan;
    '';
  };

  # Tailscale configuration
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  # userland
  users.users.ryan = {
    isNormalUser = true;
    description = "ryan";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPXxUWnqxVJOD0DHemCoYQkQq6jy+8qXdncQbjuHFPzJ ryan@Nostromo" ];
  };

  # Hardware configuration
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}