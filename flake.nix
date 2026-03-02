{
  description = "SAT Hardness Analysis Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};

        pythonEnv = pkgs.python3.withPackages (ps:
          with ps; [
            snakemake
            pandas
            matplotlib
            numpy
          ]);

        rEnv = pkgs.rWrapper.override {
          packages = with pkgs.rPackages; [
            tidyverse
          ];
        };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pythonEnv
            rEnv
            pkgs.minisat # The recommended SAT Solver
            pkgs.gcc # C++ Compiler
            pkgs.gnumake # Make for building C++ tools
            pkgs.cmake # CMake (optional, if you prefer it over Make)
            pkgs.time # Useful for precise runtime measurement
            pkgs.wget
            pkgs.xz
          ];
        };
      }
    );
}
