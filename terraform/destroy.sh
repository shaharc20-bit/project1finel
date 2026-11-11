#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if [ -n "${TF_DATA_DIR:-}" ]; then
  RS_DATA_DIR="${TF_DATA_DIR}-remote-state"
else
  RS_DATA_DIR="$PWD/remote-state/.terraform"
fi

terraform init -input=false -backend-config=backend.hcl > /dev/null
terraform destroy "$@"

read -r -p "Also delete the remote state bucket and lock table? [y/N] " answer
if [ "$answer" = "y" ]; then
  rm -rf "${TF_DATA_DIR:-.terraform}"
  TF_DATA_DIR="$RS_DATA_DIR" terraform -chdir=remote-state init -input=false > /dev/null
  TF_DATA_DIR="$RS_DATA_DIR" terraform -chdir=remote-state destroy -auto-approve
  rm -rf "$RS_DATA_DIR" backend.hcl remote-state.auto.tfvars
fi
