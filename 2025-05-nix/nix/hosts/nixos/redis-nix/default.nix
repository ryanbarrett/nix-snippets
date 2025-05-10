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
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Network configuration
  networking = {
    firewall = {
      enable = true;
      # Allow tailscale traffic
      trustedInterfaces = [ "tailscale0" ];
      # Redis port is only accessible via Tailscale, no need to open public ports
      # Allow the tailscale UDP port
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
    hostName = "redis-nix";
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
  
  # Redis configuration for production
  services.redis = {
    enable = true;
    settings = {
      # Bind to private interface and Tailscale interface
      bind = "0.0.0.0";
      # Production settings
      protected-mode = "yes";
      maxmemory = "1gb";
      maxmemory-policy = "allkeys-lru";
      # Persistence settings
      appendonly = "yes";
      appendfsync = "everysec";
      # Security (set a separate password in a secrets file in production)
      requirepass = "CHANGE_THIS_TO_A_STRONG_PASSWORD";
    };
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