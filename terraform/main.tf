data "http" "my_ip" {
  count = var.detect_my_ip ? 1 : 0
  url   = "https://checkip.amazonaws.com"
}

locals {
  my_ip_cidr    = var.detect_my_ip ? ["${chomp(data.http.my_ip[0].response_body)}/32"] : []
  allowed_cidrs = distinct(concat(var.allowed_cidrs, local.my_ip_cidr))
  param_prefix  = "/${var.project}"

  user_data = templatefile("${path.module}/templates/user-data.sh.tftpl", {
    region              = var.region
    param_prefix        = local.param_prefix
    repo_url            = var.repo_url
    repo_branch         = var.repo_branch
    backup_bucket       = var.backup_bucket
    trigger_first_build = var.trigger_first_build
    jenkins_dockerfile  = chomp(file("${path.module}/templates/jenkins/Dockerfile"))
    jenkins_plugins     = chomp(file("${path.module}/templates/jenkins/plugins.txt"))
    jenkins_compose     = chomp(file("${path.module}/templates/jenkins/docker-compose.yml"))
    jenkins_casc        = chomp(templatefile("${path.module}/templates/jenkins/casc.yaml.tftpl", { repo_url = var.repo_url, repo_branch = var.repo_branch }))
    backup_script       = chomp(file("${path.module}/templates/jenkins/backup-jenkins.sh"))
  })
}

resource "aws_ssm_parameter" "dockerhub_username" {
  name  = "${local.param_prefix}/dockerhub_username"
  type  = "String"
  value = var.dockerhub_username
}

resource "aws_ssm_parameter" "dockerhub_token" {
  name  = "${local.param_prefix}/dockerhub_token"
  type  = "SecureString"
  value = var.dockerhub_token
}

resource "aws_ssm_parameter" "github_username" {
  name  = "${local.param_prefix}/github_username"
  type  = "String"
  value = var.github_username
}

resource "aws_ssm_parameter" "github_token" {
  name  = "${local.param_prefix}/github_token"
  type  = "SecureString"
  value = var.github_token
}

resource "aws_ssm_parameter" "admin_password" {
  name  = "${local.param_prefix}/admin_password"
  type  = "SecureString"
  value = var.admin_password
}

module "builder" {
  source = "./modules/builder"

  name                = var.project
  region              = var.region
  vpc_id              = var.vpc_id
  instance_type       = var.instance_type
  root_volume_size    = var.root_volume_size
  allowed_cidrs       = local.allowed_cidrs
  open_nodeport_range = true
  user_data           = local.user_data
  backup_bucket       = var.backup_bucket
  public_key          = file(var.ssh_public_key_path)

  tcp_ports = {
    "22"   = "SSH"
    "80"   = "Ingress (Traefik)"
    "5001" = "Flask app (prd LoadBalancer)"
    "8080" = "Jenkins"
  }

  ssm_parameter_arns = [
    aws_ssm_parameter.dockerhub_username.arn,
    aws_ssm_parameter.dockerhub_token.arn,
    aws_ssm_parameter.admin_password.arn,
    aws_ssm_parameter.github_username.arn,
    aws_ssm_parameter.github_token.arn,
  ]
}

resource "terraform_data" "wait_for_bootstrap" {
  triggers_replace = [module.builder.instance_id]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.ssh_private_key_path)
    host        = module.builder.public_ip
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for user-data: Docker, Jenkins, k3s, Argo CD (10-15 minutes)...'",
      "cloud-init status --wait > /dev/null || true",
      "if [ ! -f /var/lib/devops-bootstrap/done ]; then sudo tail -n 60 /var/log/devops-bootstrap.log; exit 1; fi",
      "sudo tail -n 25 /var/log/devops-bootstrap.log",
    ]
  }

  provisioner "local-exec" {
    command = "echo ${module.builder.public_dns} > builder_dns.txt"
  }
}
