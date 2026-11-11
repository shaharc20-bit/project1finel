#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

ssh -i ssh/mykey -o StrictHostKeyChecking=accept-new "ubuntu@$(terraform output -raw public_ip)" "$@"
