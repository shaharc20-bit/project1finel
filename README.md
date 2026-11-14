# project1finel

One `terraform apply` builds the whole environment on AWS: VPC, EC2, Docker, k3s, Helm, Jenkins and Argo CD.
Jenkins builds the app, and Argo CD deploys it to Kubernetes (GitOps).

## Structure

```
app/              Code: prOne Flask app, Dockerfile
helm/flask-app/   Helm chart: Deployment (3 replicas) + LoadBalancer Service, port 5001
Jenkinsfile       CI pipeline
gitops/           Kubernetes manifests rendered by Jenkins, watched by Argo CD
terraform/        Infrastructure
```

## Flow

```
git push
  -> Jenkins: docker build -> docker push -> helm template -> git push (gitops/)
  -> Argo CD (auto sync) -> k3s (3 replicas)
```

## Pipeline

| Stage | What it does |
|---|---|
| Checkout | Image tag = short commit SHA |
| Build image | `docker build -t shaharc20/flask-aws-monitor:<sha> app` |
| Push to Docker Hub | `docker push` with the `dockerhub` credential |
| Helm template | `helm lint`, `helm template --set image.tag=<sha>` |
| Push to gitops/ | Commits `gitops/flask-app/flask-app.yaml` |

`gitops/` is written only by Jenkins. Every `Deploy ...` commit is one deployment, rollback is `git revert`.

## Infrastructure (terraform/)

| Part | Resources |
|---|---|
| `bootstrap/` | S3 bucket for the state (versioning, encryption, no public access), DynamoDB table for locking |
| `modules/network` | VPC `10.20.0.0/16`, public subnet, internet gateway, route table |
| `modules/server` | Security group (22, 5001, 8080, 30443 from my IP only), key pair, IAM instance profile, Ubuntu 24.04 EC2 (IMDSv2), Elastic IP |
| `scripts/install.sh` | user_data: Docker, git, k3s, Helm, Argo CD |
| `provision.tf` | `file` + `remote-exec`: Jenkins in Docker, configured as code (JCasC); `local-exec`: prints the Jenkins URL |
| `argocd/` | Argo CD Application (template) that points to `gitops/flask-app` |

## Run

Requirements: Terraform, AWS CLI with credentials, an SSH key:

```
ssh-keygen -t ed25519 -f ~/.ssh/aws-lab
```

Once, the remote state:

```
cd terraform/bootstrap
terraform init
terraform apply
```

The environment:

```
cd ..
cp terraform.tfvars.example terraform.tfvars   # Docker Hub token, GitHub token, admin password
terraform init
terraform apply
```

Outputs:

```
ssh_command  = ssh -i $HOME\.ssh\aws-lab ubuntu@<ip>
app_url      = http://<ip>:5001
jenkins_url  = http://<ip>:8080
argocd_url   = https://<ip>:30443
```

Jenkins and Argo CD: user `admin`, password from `terraform.tfvars`.

Remove everything: `terraform destroy` in `terraform/` (not in `bootstrap`).

## App

| Path | |
|---|---|
| `/` | Dashboard: CPU, RAM, disk, clock, sites status, quote of the day |
| `/network` | Hostname and IP (in Kubernetes: the pod) |
| `/about` | About page |
| `/health` | Health check |
| `/api/stats`, `/api/speed`, `/api/sites`, `/api/quote` | JSON |

Run locally:

```
cd app
pip install -r requirements.txt
python one.py                      # http://localhost:6555
```

## Security

- `terraform.tfvars` and `*.tfstate` are not in git.
- Tokens are uploaded over SSH to `/opt/jenkins/.env` (mode 600), not in user_data.
- Jenkins reads them by credential ID (`dockerhub`, `github`) and masks them in logs.
- State in S3 is encrypted, versioned and locked.
- Ports are open only to my IP. IMDSv2 is required.
- Image: multi-stage, non-root user (`10001`), pinned dependencies, `HEALTHCHECK`, no debug mode, resource limits.
