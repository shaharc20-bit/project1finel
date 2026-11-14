#!/bin/bash
set -euo pipefail
exec > /var/log/install.log 2>&1
export HOME=/root

echo "=== 1/4 Docker + git"
apt-get update -y
apt-get install -y docker.io git curl
systemctl enable --now docker
usermod -aG docker ubuntu

echo "=== 2/4 Kubernetes (k3s)"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644" sh -
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube
until kubectl get nodes | grep -q " Ready"; do sleep 5; done

echo "=== 3/4 Helm"
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "=== 4/4 Argo CD"
kubectl create namespace argocd
kubectl apply -n argocd --server-side \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deploy/argocd-server --timeout=600s
kubectl -n argocd patch svc argocd-server \
  -p '{"spec":{"type":"NodePort","ports":[{"name":"https","port":443,"targetPort":8080,"nodePort":30443}]}}'

echo "INSTALL DONE"
