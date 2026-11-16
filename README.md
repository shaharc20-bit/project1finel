# project1finel - code repository

Flask AWS Monitor: the application, its Docker image, the CI pipelines and the Helm chart.
Jenkins builds the image and hands the result to the **GitOps repo**, and Argo CD deploys it to Kubernetes.

## The repositories

| Repository | Holds |
|---|---|
| **project1finel** (this one) | app, Dockerfile, Jenkinsfile, Azure pipeline, Helm chart, k8s manifests, shared library |
| [project1-gitops](https://github.com/shaharc20-bit/project1-gitops) | what Argo CD deploys: dev/qa/prd values, ApplicationSets, bonus apps |
| [project1-terraform](https://github.com/shaharc20-bit/project1-terraform) | AWS infrastructure: VPC, EC2, Docker, k3s, Jenkins, Argo CD, and the exam "builder" |

## Structure

```
app/                    Flask AWS Monitor (app.py, fixed), Dockerfile, tests, docker-compose.yml  (+ prOne app: one.py)
helm/flask-app/         Helm chart: Deployment, Service, optional Ingress, AWS keys from aws-values.yaml (git-ignored)
Jenkinsfile             CI pipeline: parallel lint + security scan, build, push, helm template, push to the GitOps repo
azure-pipelines.yml     Azure DevOps pipeline with the same stages (bonus)
k8s/                    plain Kubernetes manifests (Section 7)
shared-library/         Jenkins shared library (vars/), optional
docs/evidence/          logs and screenshots that show every part working
```

Every folder has its own `README.md`: what is implemented, what is missing, how to run it.

## Flow

```
git push (merge to main)
  -> Jenkins: parallel lint + scan -> docker build -> docker push -> helm template
  -> git push to project1-gitops
  -> Argo CD (auto sync) -> k3s
```

## Pipeline (Jenkinsfile)

| Stage | What it does |
|---|---|
| Checkout | Image tag = short commit id of this repo |
| Parallel Checks | flake8, hadolint, shellcheck, helm lint, bandit, trivy fs, pytest - at the same time |
| Build image | `docker build -t shaharc20/flask-aws-monitor:<tag> app` |
| Scan image | trivy |
| Push to Docker Hub | `docker push` with the `dockerhub` credential |
| Helm template | `helm lint`, `helm template --set image.tag=<tag>` |
| Push to GitOps repo | all-in-one yaml, copy of the chart, new image tag for `dev` |

`MOCK_CHECKS=true` prints `MOCK: ...` instead of running the lint and scan tools (the exam allows mocks).

## App

The Docker image runs **`app/app.py`** - the exam application (EC2 instances, VPCs, Load Balancers, AMIs; port 5001; `/health`).
The earlier prOne app (`app/one.py`) is still in the folder; switch back by changing the last line of `app/Dockerfile` to `CMD ["python", "one.py"]`.

```
cd app
pip install -r requirements-dev.txt
python -m pytest -q tests          # mocked AWS (moto)
AWS_REGION=us-east-1 python app.py # http://localhost:5001  (AWS keys from the environment)
```

## Security

- AWS keys and tokens are never in git: environment variables, `aws-values.yaml` (git-ignored), Jenkins credentials (`dockerhub`, `github`).
- Image: multi-stage, non-root user (`10001`), `HEALTHCHECK`, no debug mode, resource limits in the chart.

## Exam sections -> where to find them

| Section | Where |
|---|---|
| 1 Git repository, Git Flow | all repos: `main`, `dev`, `feature/*`, tags |
| 3 Dockerize the app | `app/Dockerfile`, `app/docker-compose.yml` (branch `feature/aws-app`) |
| 4 Fix the bug | `app/app.py`, `app/tests/` (`feature/fix-bug`) |
| Terraform: EC2 builder | repo **project1-terraform**, folder `builder/` |
| 5 Jenkins (parallel lint + scan, build, push) | `Jenkinsfile` (`feature/jenkins-ci`) |
| 5.1 Azure DevOps (bonus) | `azure-pipelines.yml` (`feature/azure-pipeline`) |
| 7 Kubernetes | `k8s/` (`feature/k8s-manifests`) |
| Helm | `helm/flask-app/` (`feature/helm-chart`) |
| 8 Argo CD, ApplicationSets, dev/qa/prd | repo **project1-gitops** |
| Shared libraries (optional) | `shared-library/` (`feature/shared-library`) |

## Git Flow

- `main` only changes through a **pull request** from `dev` (no direct pushes by people). Every merge into `main` gets a tag (`v1.0.0`, ...).
- Every section is developed in its own `feature/*` branch, merged into `dev` (`--no-ff`), and `dev` goes to `main` with a pull request.
- The first versions of the Terraform and GitOps parts were written in this repo (branches `feature/terraform-builder`, `feature/gitops-environments`) and then moved to their own repositories in `feature/split-repos`.
- The Jenkins bot commits `Deploy ...` to `main` of **project1-gitops** (that is the GitOps hand-over to Argo CD).

## Blockers and notes

- The VPC `vpc-044604d0bfb707142` of the exam exists only in the instructor's account (see the `builder/` README in project1-terraform).
- Proof that everything runs: `docs/evidence/`.
