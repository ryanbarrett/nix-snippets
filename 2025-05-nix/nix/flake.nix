{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { ... }@inputs:
    with inputs;
    let
      inherit (self) outputs;
      stateVersion = "24.11";
      libx = import ./lib { inherit inputs outputs stateVersion pkgs; };
    in {
      nixosConfigurations = {

        # Add the n8n server configuration
        n8n-nix = libx.mkNixos {
          system = "x86_64-linux";
          hostname = "n8n-nix";
          username = "ryan";
        };
        
        # Add the Redis server configuration
        redis-nix = libx.mkNixos {
          system = "x86_64-linux";
          hostname = "redis-nix";
          username = "ryan";
        };
        
        # Add the PostgreSQL server configuration
        postgres-nix = libx.mkNixos {
          system = "x86_64-linux";
          hostname = "postgres-nix";
          username = "ryan";
        };
      };
   };
}