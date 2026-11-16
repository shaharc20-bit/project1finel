# k8s/ - plain Kubernetes manifests (Section 7)

## What was implemented
- `namespace.yaml` - namespace `flask-monitor`
- `deployment.yaml` - 2 replicas of `shaharc20/flask-aws-monitor:latest`, port 5001, probes on `/health`, resource requests/limits, non-root
- `service.yaml` - `LoadBalancer` on port 5001
- `aws-secret.example.yaml` - example only. On EC2 the pods use the node IAM role, so the secret is optional (`optional: true` in the Deployment)

These manifests are the manual way. The automatic way (Jenkins -> `gitops/` -> Argo CD) uses the Helm chart in `../helm`.

## Missing / blockers
- None. Real AWS keys are never committed; create the Secret with kubectl.

## Deploy to the remote cluster (k3s on the server)
```bash
kubectl apply -f k8s/namespace.yaml
# optional, only when the node has no IAM role:
kubectl create secret generic aws-credentials -n flask-monitor \
  --from-literal=AWS_ACCESS_KEY_ID=... --from-literal=AWS_SECRET_ACCESS_KEY=...
kubectl apply -f k8s/deployment.yaml -f k8s/service.yaml
kubectl get pods,svc -n flask-monitor
```
Open `http://<EXTERNAL-IP>:5001/` (the public IP of the server on k3s). Without a LoadBalancer: `kubectl port-forward svc/flask-aws-monitor -n flask-monitor 5001:5001`.

Clean up: `kubectl delete -f k8s/`.
