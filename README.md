# project1finel

One `terraform apply` builds the whole environment on AWS: VPC, EC2, Docker, k3s, Helm, Jenkins and Argo CD.
Jenkins builds the app, and Argo CD deploys it to Kubernetes (GitOps).

## Structure

```
app/                    Flask AWS Monitor (app.py, fixed), Dockerfile, tests, docker-compose.yml  (+ prOne app: one.py)
helm/flask-app/         Helm chart: Deployment, Service, optional Ingress, AWS keys from aws-values.yaml (git-ignored)
Jenkinsfile             CI pipeline: parallel lint + security scan, build, push, helm template, gitops
azure-pipelines.yml     Azure DevOps pipeline with the same stages (bonus)
k8s/                    plain Kubernetes manifests (Section 7)
gitops/                 what Argo CD deploys: all-in-one yaml, dev/qa/prd values, ApplicationSets, bonus apps
shared-library/         Jenkins shared library (vars/), optional
terraform/              Infrastructure of the lab: VPC, EC2, Docker, k3s, Helm, Jenkins, Argo CD
terraform/builder/      Exam task: EC2 "builder" with Docker + Compose in the existing VPC (us-east-1)
docs/evidence/          logs and screenshots that show every part working
```

Every folder has its own `README.md`: what is implemented, what is missing, how to run it.

## Flow

```
git push
  -> Jenkins: docker build -> docker push -> helm template -> git push (gitops/)
  -> Argo CD (auto sync) -> k3s (3 replicas)
```

## Pipeline

| Stage | What it does |
|---|---|
| Checkout | Image tag = short SHA of the last commit that changed `app/` or `helm/` |
| Build image | `docker build -t shaharc20/flask-aws-monitor:<sha> app` |
| Push to Docker Hub | `docker push` with the `dockerhub` credential |
| Helm template | `helm lint`, `helm template --set image.tag=<sha>` |
| Push to gitops/ | Commits `gitops/flask-app/flask-app.yaml` |

`gitops/` is written only by Jenkins. Every `Deploy ...` commit is one deployment, rollback is `git revert`.
A build on a Jenkins commit gets the same tag, so `gitops/` does not change and there is no build loop.

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

The Docker image runs **`app/app.py`** - the exam application (Flask AWS Monitor: EC2 instances, VPCs, Load Balancers, AMIs; port 5001; `/health`).
The earlier prOne app (`app/one.py`, dashboard with CPU/RAM/disk) is still in the folder; switch back by changing the last line of `app/Dockerfile` to `CMD ["python", "one.py"]`.

Run locally:

```
cd app
pip install -r requirements-dev.txt
python -m pytest -q tests          # mocked AWS (moto)
AWS_REGION=us-east-1 python app.py # http://localhost:5001  (AWS keys from the environment)
```

## Security

- `terraform.tfvars` and `*.tfstate` are not in git.
- Tokens are uploaded over SSH to `/opt/jenkins/.env` (mode 600), not in user_data.
- Jenkins reads them by credential ID (`dockerhub`, `github`) and masks them in logs.
- State in S3 is encrypted, versioned and locked.
- Ports are open only to my IP. IMDSv2 is required.
- Image: multi-stage, non-root user (`10001`), pinned dependencies, `HEALTHCHECK`, no debug mode, resource limits.

## Exam sections -> where to find them

| Section | Folder / file | Feature branch |
|---|---|---|
| 1 Git repository, Git Flow | this repo: `main`, `dev`, `feature/*`, tags | - |
| 3 Dockerize the app | `app/Dockerfile`, `app/docker-compose.yml` | `feature/aws-app` |
| 4 Fix the bug | `app/app.py`, `app/tests/` | `feature/fix-bug` |
| Terraform: EC2 builder | `terraform/builder/` | `feature/terraform-builder` |
| 5 Jenkins (parallel lint + security scan, build, push) | `Jenkinsfile` | `feature/jenkins-ci` |
| 5.1 Azure DevOps (bonus) | `azure-pipelines.yml` | `feature/azure-pipeline` |
| 7 Kubernetes | `k8s/` | `feature/k8s-manifests` |
| Helm | `helm/flask-app/` | `feature/helm-chart` |
| 8 Argo CD, ApplicationSets, dev/qa/prd | `gitops/` | `feature/gitops-environments` |
| Shared libraries (optional) | `shared-library/` | `feature/shared-library` |

## Git Flow

- `main` only changes through a **pull request** from `dev` (no direct pushes by people). Every merge into `main` gets a tag (`v1.0.0`, ...).
- Every section is developed in its own `feature/*` branch, merged into `dev` (`--no-ff`), and `dev` goes to `main` with one pull request.
- Exception: the Jenkins bot commits `Deploy ...` messages to `main`, only inside `gitops/` (that is the GitOps hand-over to Argo CD).
- Mocks: `MOCK_CHECKS=true` in Jenkins/Azure prints the lint and scan steps instead of running them. By default the real tools run (flake8, hadolint, shellcheck, helm lint, bandit, trivy).

## Blockers and notes

- The VPC `vpc-044604d0bfb707142` of the exam exists only in the instructor's account (see `terraform/builder/README.md`).
- The GitOps part is a folder (`gitops/`) of this repository, not a separate repository.
- Proof that everything runs: `docs/evidence/`.
