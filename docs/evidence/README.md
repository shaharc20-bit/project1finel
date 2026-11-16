# docs/evidence - proof that each part works

Put the screenshots / logs here (file name -> what it shows). Do not include keys, tokens or passwords.

| File | Shows |
|---|---|
| `01-git-branches.png` | `git log --oneline --graph` or GitHub network: feature branches -> dev -> pull request -> main, tags |
| `02-app-bug-before.png` | Section 3: the page with the error (original code) |
| `03-app-fixed.png` | Section 4: EC2, VPCs, Load Balancers, AMIs listed |
| `04-terraform-apply.txt` | `terraform apply` + `terraform output` of `builder/` (repo project1-terraform) |
| `05-docker-version.txt` | `docker --version` and `docker compose version` on the builder |
| `06-security-group.png` | Security group: only ports 22 and 5001 from my IP |
| `07-jenkins-pipeline.png` | Jenkins: all stages green, parallel checks visible |
| `08-dockerhub.png` | The image tag in Docker Hub |
| `09-helm-deploy.txt` | `helm install` / `kubectl get pods,svc` |
| `10-argocd-apps.png` | Argo CD: `flask-aws-monitor-dev/qa/prd`, `stress-app-*`, bonus apps - Synced / Healthy |
| `11-env-differences.txt` | `kubectl get deploy -A` (replicas per environment) |
| `12-git-change-sync.png` | A change in the GitOps repo and Argo CD syncing it |
