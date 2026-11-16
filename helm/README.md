# helm/ - chart that deploys the Flask AWS Monitor

```
helm/flask-app/
  Chart.yaml
  values.yaml                 defaults: image, replicas, service, ingress, aws keys, resources
  aws-values.yaml.example     template for the AWS keys (copy to aws-values.yaml - git-ignored)
  templates/ deployment.yaml  service.yaml  ingress.yaml  secret.yaml
```

## What was implemented
- Deployment: image from Docker Hub (`shaharc20/flask-aws-monitor`), port 5001, `replicaCount`, resource requests and limits, region from `awsRegion`.
- Service: `ClusterIP`, `NodePort` (with `service.nodePort`) or `LoadBalancer`, port 5001 - chosen per environment in `values.yaml`.
- Ingress (bonus): `ingress.enabled=true`, host and path.
- AWS keys as environment variables from a Secret. The keys live in **`aws-values.yaml`** which is in `.gitignore`. Without keys the pods use the IAM role of the EC2 node.
- Jenkins renders the chart with `helm template` into `flask-app/flask-app.yaml` of the GitOps repo (project1-gitops) and copies the chart there for the ApplicationSets; Argo CD deploys it.

## Missing / blockers
- None. The chart directory is `flask-app` (not `flask-aws-monitor`), because the pipeline and Argo CD already use this path.

## Use (needs a Kubernetes cluster, e.g. the k3s on the server)
```bash
cp helm/flask-app/aws-values.yaml.example aws-values.yaml     # fill in the keys (optional on EC2 with an IAM role)
helm lint helm/flask-app
helm install flask-monitor ./helm/flask-app -f aws-values.yaml
kubectl get pods,svc
kubectl get svc flask-monitor                                  # EXTERNAL-IP, then http://<ip>:5001/

helm upgrade flask-monitor ./helm/flask-app --set replicaCount=3
helm history flask-monitor
helm rollback flask-monitor 1
```
Ingress (bonus): `--set ingress.enabled=true --set ingress.host=flask.example.com`.
Without a cluster: `helm template flask-monitor ./helm/flask-app` prints the manifests.
