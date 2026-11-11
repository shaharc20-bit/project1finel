#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p ssh
if [ -f ssh/mykey ]; then
  echo "ssh/mykey already exists"
else
  ssh-keygen -t rsa -b 4096 -f ssh/mykey -N "" -C "terraform-builder"
fi
chmod 600 ssh/mykey
