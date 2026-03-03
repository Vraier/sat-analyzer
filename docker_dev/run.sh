#!/bin/bash
# Move to script directory so it works from anywhere
cd "$(dirname "$0")"
docker-compose up -d --build
echo "Container started. Use ./enter.sh to go inside."