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
      # Allow HTTP/HTTPS traffic
      allowedTCPPorts = [ 80 443 ];
      # Allow the tailscale UDP port
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
    hostName = "n8n-nix";
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
  
  # n8n service configuration
  services.n8n = {
    enable = true;
    settings = {
      # Default port is 5678
      port = 5678;
      # Bind to localhost so only Caddy can access it directly
      host = "127.0.0.1";
    };
  };

  # Tailscale configuration
  services.tailscale = {
    enable = true;
    permitCertUid = "caddy"; # Allow Caddy to use Tailscale certs
    useRoutingFeatures = "client";
  };

  # Caddy for reverse proxy with automatic HTTPS from Tailscale
  services.caddy = {
    enable = true;
    virtualHosts."n8n.serengeti-duck.ts.net" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:5678
      '';
    };
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