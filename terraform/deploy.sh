#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if [ -n "${TF_DATA_DIR:-}" ]; then
  RS_DATA_DIR="${TF_DATA_DIR}-remote-state"
else
  RS_DATA_DIR="$PWD/remote-state/.terraform"
fi

./generate_ssh_key.sh

if [ ! -f backend.hcl ]; then
  TF_DATA_DIR="$RS_DATA_DIR" terraform -chdir=remote-state init -input=false
  TF_DATA_DIR="$RS_DATA_DIR" terraform -chdir=remote-state apply -auto-approve
  rm -rf "$RS_DATA_DIR"
fi

terraform init -input=false -backend-config=backend.hcl
terraform apply "$@"
