# common.nix
{ config, pkgs, ... }:

{

  time.timeZone = "America/New_York";

  
  # Common packages across all systems
  environment.systemPackages = with pkgs; [
    neovim
    git
    curl
    wget
    htop
    tmux
  ];

  # Common system settings
  services.openssh.enable = true;

  # Common shell aliases
  environment.shellAliases = {
    ll = "ls -lah";
    nixrebuild = "sudo cp -r /etc/nixos /etc/nixos.backup.$(date +%Y%m%d_%H%M%S) && sudo nixos-rebuild switch";
  };

 
  # SSH Server configuration
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Create user farscape with SSH access
  users.users.farscape = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 $$$$$$$ test"
    ];
  };


  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
  };

  nix = {
    settings = {
        # 500mb buffer
        download-buffer-size = 500000000;
        auto-optimise-store = true;
    };
    # Automate garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 10d";
    };
  };



  system.stateVersion = "24.11";
}