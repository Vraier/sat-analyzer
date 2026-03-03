#!/bin/bash
# Move to script directory so it works from anywhere
cd "$(dirname "$0")"
docker exec sat-dev git config --global --add safe.directory /app
docker exec -it sat-dev nix develop --extra-experimental-features "nix-command flakes" -c bash
echo "Welcome to SAT dev environment"