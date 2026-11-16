# terraform/builder - exam task (EC2 "builder" with Docker + Docker Compose)

Separate Terraform configuration (own state) for the exam task. It does **not** touch the lab in `../` (k3s, Jenkins, Argo CD).

## What was implemented
- Region `us-east-1`, the **existing VPC `vpc-044604d0bfb707142`** (no VPC is created) and its first public subnet.
- EC2 instance named **`builder`**, `t3.medium`, Ubuntu 24.04.
- SSH key: `tls_private_key` -> `local_file` `builder_key.pem` (mode 0600, git-ignored) -> `aws_key_pair` `builder-key`.
- Security group: ports **22** and **5001**, only from **my IP** (found with checkip.amazonaws.com), all outbound allowed.
- **Docker + Docker Compose installed by Terraform** with `remote-exec` (bonus). `install_docker = false` skips it (then install manually, Option 1).
- Outputs: `public_ip`, `ssh_private_key_path`, `ssh_key_name`, `security_group_id`, `ssh_command`, `app_url`.

## Missing / blockers
- The VPC `vpc-044604d0bfb707142` exists only in the instructor's AWS account. In another account `terraform plan` fails on the VPC lookup; pass your own with `-var vpc_id=vpc-...`.
- Jenkins is not installed here; the Jenkins + Argo CD setup is in `../` (see `../README.md`).

## Run
```bash
cd terraform/builder
aws configure                      # or export AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_DEFAULT_REGION=us-east-1
terraform init
terraform plan
terraform apply
terraform output
```

Connect (the key file is created next to the code):
```bash
ssh -i builder_key.pem ubuntu@<public_ip>
docker --version && docker compose version
```
Windows: if ssh says "bad permissions", run `icacls builder_key.pem /inheritance:r /grant:r "%USERNAME%:R"`.

Run the app on the builder (Section 3):
```bash
git clone https://github.com/shaharc20-bit/project1finel.git && cd project1finel/app
docker compose up -d --build
```
Open `http://<public_ip>:5001/`.

Destroy when finished: `terraform destroy`.

## Validation done
`terraform validate`, `terraform fmt -check`, and an apply against a mocked AWS API (instance named `builder`, SG with 22 and 5001 from one /32, outputs present).
