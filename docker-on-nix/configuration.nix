# /etc/nixos/configuration.nix
{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./common.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable Docker service
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  systemd.services.docker-proxy-network = {
    description = "Create Docker proxy network";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = ''
        ${pkgs.runtimeShell} -c "if ! ${pkgs.docker}/bin/docker network inspect proxy >/dev/null 2>&1; then ${pkgs.docker}/bin/docker network create proxy; fi"
      '';
    };
  };


  virtualisation.vmware.guest.enable = true;


  networking.hostName = "docker-nix2025";

  networking = {
    # Disable DHCP
    useDHCP = true;

    # Configure the network interface (replace "ens192" with your actual interface name)
    interfaces.ens33 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "10.1.1.24"; # Replace with your desired IP
        prefixLength = 24;         # Replace with your subnet mask prefix length
      }];
    };

    # Default gateway and DNS servers
    defaultGateway = "10.1.1.1";      # Replace with your gateway IP
    nameservers = [ "1.1.1.1" "1.0.0.1" ]; # Replace with your DNS servers
    firewall = {
      enable = true;
      # Allow tailscale traffic
      trustedInterfaces = [ "tailscale0" ];
      # Allow HTTP/HTTPS traffic
      allowedTCPPorts = [ 80 443 ];
      # Allow the tailscale UDP port
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
  };




  # Caddy for reverse proxy with automatic HTTPS from Tailscale
  services.caddy = {
    enable = true;
    virtualHosts."docker-nix2025.floppy-donkey.ts.net" = {
      #listenAddresses = [ "100.xx.xx.xx" ];
      extraConfig = ''
        reverse_proxy http://127.0.0.1:5001
      '';
    };
  };

  # Tailscale configuration
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    permitCertUid = "caddy";
  };

  # Create directory for Dockge
  system.activationScripts.dockgeDirectories = ''
    mkdir -p /opt/dockge/data
    mkdir -p /opt/dockge/compose
    mkdir -p /opt/stacks
  '';

# Create directory for traefik
  system.activationScripts.traefikFiles = ''
    mkdir -p /opt/stacks/traefik/data/
    touch /opt/stacks/traefik/data/acme.json
    chmod 600 /opt/stacks/traefik/data/acme.json
  '';


  # Run Dockge directly with Docker instead of using oci-containers
  systemd.services.dockge = {
    description = "Dockge Container";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.docker}/bin/docker run --name dockge --restart=always -p 127.0.0.1:5001:5001 -v /var/run/docker.sock:/var/run/docker.sock -v /opt/dockge/data:/app/data -v /opt/stacks:/opt/stacks -v /opt/dockge/compose:/opt/compose -e PUID=1000 -e PGID=1000 -e DOCKGE_STACKS_DIR=/opt/stacks louislam/dockge:latest";
      ExecStop = "${pkgs.docker}/bin/docker stop dockge";
      ExecStopPost = "${pkgs.docker}/bin/docker rm -f dockge";
      Type = "simple";
      Restart = "on-failure";
    };
  };


}