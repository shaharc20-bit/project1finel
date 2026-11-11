# Helm chart - flask-aws-monitor

```
values/ dev.yaml qa.yaml prd.yaml   per-environment values used by the CI (helm template -> gitops/envs)
flask-aws-monitor/
  Chart.yaml
  values.yaml
  aws-values.yaml.example
  templates/ deployment, service, ingress, secret, hpa, NOTES.txt, _helpers.tpl
```

`values.yaml`: image + tag (`latest`, pullPolicy Always), replicas, service type/port (5001), ingress, env, resources, autoscaling.
AWS keys go in `aws-values.yaml` (git-ignored). Use `aws.existingSecret` to point to a secret created with kubectl instead.

```bash
cd code/helm
cp flask-aws-monitor/aws-values.yaml.example aws-values.yaml   # fill in keys
helm lint flask-aws-monitor
helm install flask-monitor ./flask-aws-monitor -f aws-values.yaml
kubectl get pods,svc
kubectl get svc flask-monitor-flask-aws-monitor      # EXTERNAL-IP
helm upgrade flask-monitor ./flask-aws-monitor -f aws-values.yaml --set replicaCount=3
helm history flask-monitor
helm rollback flask-monitor 1
```
Ingress (bonus): `--set ingress.enabled=true --set ingress.host=flask-monitor.local` (needs an ingress controller).
