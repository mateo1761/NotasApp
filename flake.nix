{
  description = ''
    === Feel Chat Development Environment

    !!! Dev Environments
    - frontend: Creates a Flutter development Environment with an android emulator
    - backend: Creates a Java Spring Development Environment

    !!! Runables
    - backend: runs the backend projects.
    - start-db: Creates and initialize a PostgreSQL database that store the data in a folder called .pgdata
    - stop-db: Stop the PostgreSQL database
    - reset-db: Reset (delete the .pgdata folder) and Stop the PostgreSQL database
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    # Environments
    devShells."${system}" = {
      # Backend
      backend = pkgs.mkShell {
        buildInputs = with pkgs; [
          nodejs
        ];

        shellHook = ''
          if [[ $(basename "$PWD") != "backend" ]]; then
            echo "> You're not in the required folder 'backend/' "
            exit
          fi
        '';
      };

      # Frontend
      frontend = pkgs.mkShell {
        buildInputs = [];
        shellHook = ''
          if [[ $(basename "$PWD") == "frontend" ]]; then
            nix develop --refresh github:K1-mikaze/Nix-Environments/main?dir=flakes/language/dart
            exit
          else
            echo "> You're not in the required folder 'frontend/' "
            exit
          fi
        '';
      };
    };

    # Runnables
    apps."${system}" = {
      emulator = {
        type = "app";
        program = let
          script = pkgs.writeShellScriptBin "start-backend" ''
            nix run --refresh github:K1-mikaze/Nix-Environments/main?dir=flakes/language/dart#emulator
          '';
        in "${script}/bin/start-backend";
      };
    };
  };
}
