# project1finel

One `terraform apply` builds the whole platform on AWS: an EC2 builder with Docker, Jenkins, k3s (Kubernetes), Helm and Argo CD, an S3 bucket + DynamoDB table for the Terraform state, and daily Jenkins backups to S3.

```
code/       Flask app, Dockerfile, Helm chart, Jenkinsfile   (code repo)
gitops/     ApplicationSets + rendered manifests per env     (GitOps repo for Argo CD)
terraform/  remote state, builder module, user-data          (Terraform repo)
```

```
git push (code/)
  -> Jenkins: flake8, hadolint, shellcheck, helm lint, bandit, trivy, pytest
  -> docker build -> trivy image -> docker push (Docker Hub)
  -> helm template (dev / qa / prd)
  -> git push gitops/envs/<env>
  -> Argo CD (ApplicationSet) -> k3s: flask-dev, flask-qa, flask-prd
```

## Requirements

- AWS CLI with credentials, Terraform >= 1.10
- Docker Hub access token (Read & Write)
- GitHub token with `repo` scope

## Deploy

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
export TF_DATA_DIR=/tmp/tfdata   # AWS CloudShell only (1 GB home)
./deploy.sh
```

`deploy.sh` creates the SSH key (`ssh/mykey`), creates the state bucket and lock table (`remote-state/`) on the first run, then runs `terraform init` + `terraform apply`. The apply waits until the bootstrap on the EC2 is finished (about 15 minutes).

## Access

```bash
terraform output
./ssh.sh
```

| | URL | User |
|---|---|---|
| Jenkins | `http://<public_ip>:8080` | admin / `admin_password` |
| Argo CD | `https://<public_ip>:30443` | admin / `admin_password` |
| App (prd) | `http://<public_ip>:5001`, `http://<public_ip>/` | |
| App (dev, qa) | `kubectl get svc -n flask-dev` / `-n flask-qa` | |

## Destroy

```bash
cd terraform
./destroy.sh
```
