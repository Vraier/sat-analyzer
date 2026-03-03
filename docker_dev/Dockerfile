FROM nixos/nix:latest AS builder

WORKDIR /app
COPY flake.nix flake.lock ./

RUN nix print-dev-env --extra-experimental-features "nix-command flakes" > /dev/null

FROM nixos/nix:latest

WORKDIR /app
