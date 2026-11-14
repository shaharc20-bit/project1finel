#!/bin/bash
set -euo pipefail
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "=== Jenkins: build image (docker CLI + plugins)"
mkdir -p /opt/jenkins
cp /tmp/jenkins/Dockerfile /tmp/jenkins/casc.yaml /opt/jenkins/
install -m 600 /tmp/jenkins.env /opt/jenkins/.env
rm -f /tmp/jenkins.env
docker build -t jenkins-casc /opt/jenkins

echo "=== Jenkins: start container"
docker rm -f jenkins 2> /dev/null || true
docker run -d --name jenkins --restart unless-stopped \
  -p 8080:8080 \
  --env-file /opt/jenkins/.env \
  -v jenkins_home:/var/jenkins_home \
  -v /opt/jenkins/casc.yaml:/var/jenkins_home/casc.yaml:ro \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --group-add "$(getent group docker | cut -d: -f3)" \
  jenkins-casc

for _ in $(seq 1 60); do
  [ "$(curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/login || true)" = "200" ] && break
  sleep 5
done
curl -sf -o /dev/null http://localhost:8080/login
echo "Jenkins is up"

echo "=== Argo CD: admin password"
set -a
# shellcheck disable=SC1091
. /opt/jenkins/.env
set +a
HASH=$(kubectl -n argocd exec deploy/argocd-server -- argocd account bcrypt --password "$JENKINS_ADMIN_PASSWORD")
kubectl -n argocd patch secret argocd-secret \
  -p "{\"stringData\":{\"admin.password\":\"$HASH\",\"admin.passwordMtime\":\"$(date +%FT%T%Z)\"}}"

echo "JENKINS SETUP DONE"
