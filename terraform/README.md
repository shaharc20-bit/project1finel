# terraform/ - the lab: everything with one `terraform apply`

Region `eu-north-1`. Builds a VPC, an Ubuntu EC2 server and installs Docker, k3s, Helm, Argo CD and Jenkins; creates the Argo CD Applications.
The exam task (EC2 "builder" in the existing VPC, `us-east-1`) is a separate configuration in `builder/` - see `builder/README.md`.

## What was implemented
| Part | Resources |
|---|---|
| `bootstrap/` | S3 bucket for the state (versioning, encryption), DynamoDB table for locking |
| `modules/network` | VPC `10.20.0.0/16`, public subnet, internet gateway, route table |
| `modules/server` | Security group (22, 5001, 8080, 30443, 30501, 30502 from my IP only), key pair, IAM role (read-only EC2/ELB), Ubuntu 24.04 EC2 with IMDSv2, Elastic IP |
| `scripts/install.sh` | user_data: Docker, git, k3s, Helm, Argo CD |
| `provision.tf` | `remote-exec`: Jenkins in Docker (configured as code), Argo CD Applications (`flask-app`, `applicationsets`) |
| `jenkins/` | Dockerfile (docker CLI + helm), `casc.yaml` (credentials and the pipeline job) |
| `argocd/` | Templates of the Argo CD Applications |

## Missing / blockers
- None known. Tokens are passed as variables (`terraform.tfvars`, git-ignored), never stored in git.

## Run
```
ssh-keygen -t ed25519 -f ~/.ssh/aws-lab         # once
cd terraform/bootstrap && terraform init && terraform apply     # once: remote state
cd .. && cp terraform.tfvars.example terraform.tfvars           # fill in the tokens and the password
terraform init && terraform plan && terraform apply
terraform output
```
Remove everything: `terraform destroy` in this folder (not in `bootstrap`).
