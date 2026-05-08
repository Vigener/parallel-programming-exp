{
  description = "Parallel Programming Experiment Environment";
  inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
      flake-utils.url = "github:numtide/flake-utils";
    };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # --- HPC & C++ ---
            gcc
            gdb
            gnumake
            openmpi

            # --- Python 3.12 & uv ---
            python312
            uv
            typst

            # --- Utilities ---
            git
            curl
          ];

          shellHook = ''
            export LANG=C.UTF-8
            echo "======================================================"
            echo "Welcome to the Parallel Programming Experiment Environment!"
            echo "======================================================"
            echo " - Python : $(python3 --version)"
            echo " - uv     : $(uv --version)"
            echo "======================================================"
            
            # uv環境の自動設定（初回のみ仮想環境を作成）
            if [ ! -d ".venv" ]; then
              echo "🛠️  Creating initial uv virtualenv..."
              uv venv
            fi
            source .venv/bin/activate
          '';
        };
      }
    );
}