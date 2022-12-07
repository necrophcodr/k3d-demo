{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05";
    utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, utils, ...}:
  let
    mkOsConfig = host: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./nix/${host}/configuration.nix ];
    };
  in
  {
    nixosConfigurations."k3d-server" = mkOsConfig "k3d-server";
    nixosConfigurations."ldap-server" = mkOsConfig "ldap-server";
    colmena = 
    let
      mkDeploy = host: {name, nodes, ...}: {
        nixpkgs.system = "x86_64-linux";
        imports = [ ./nix/${host}/configuration.nix ];
        deployment = {
          targetUser = "vagrant";
          targetHost = host;
        };
      };
    in {
      meta.nixpkgs = import nixpkgs { system = "x86_64-linux"; };
      k3d-server = mkDeploy "k3d-server";
      ldap-server = mkDeploy "ldap-server";
    };
  } // utils.lib.eachDefaultSystem(system:
    let pkgs = import nixpkgs { inherit system; }; in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          docker
          docker-compose
          kubectl
          kube3d
          gnumake
          vagrant
          terraform
          colmena
          argocd
        ];
      };
    });
}