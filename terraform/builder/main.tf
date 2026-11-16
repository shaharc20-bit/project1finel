# Exam task: EC2 "builder" with Docker + Docker Compose in us-east-1, inside the EXISTING VPC.
# No VPC is created here (exam rule). Everything else is created by this configuration.

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws   = { source = "hashicorp/aws", version = "~> 6.0" }
    tls   = { source = "hashicorp/tls", version = "~> 4.0" }
    local = { source = "hashicorp/local", version = "~> 2.5" }
    http  = { source = "hashicorp/http", version = "~> 3.4" }
  }
}

provider "aws" {
  region = var.region
}

# ---------------------------------------------------------------- existing network
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# A public subnet of that VPC (auto-assigns public IPs). Set var.subnet_id to choose one yourself.
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

locals {
  subnet_id = var.subnet_id != "" ? var.subnet_id : sort(data.aws_subnets.public.ids)[0]

  # Only my IP may connect (exam: "restrict inbound access to the student's IP")
  my_ip_cidr = var.my_ip_cidr != "" ? var.my_ip_cidr : "${chomp(data.http.my_ip[0].response_body)}/32"
}

data "http" "my_ip" {
  count = var.my_ip_cidr == "" ? 1 : 0
  url   = "https://checkip.amazonaws.com"
}

# ---------------------------------------------------------------- AMI (Ubuntu 24.04 supports Docker)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# ---------------------------------------------------------------- SSH key
# Generate an SSH key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the private key locally (git-ignored: *.pem)
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/builder_key.pem"
  file_permission = "0600"
}

# Create an AWS key pair using the public key
resource "aws_key_pair" "builder_key" {
  key_name   = "builder-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# ---------------------------------------------------------------- security group
resource "aws_security_group" "builder" {
  name        = "builder-sg"
  description = "SSH (22) and Flask app (5001) from my IP only"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
  }

  ingress {
    description = "Flask app"
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
  }

  egress {
    description = "All outbound (package downloads, Docker Hub)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "builder-sg"
  }
}

# ---------------------------------------------------------------- the instance
resource "aws_instance" "builder" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.builder.id]
  key_name                    = aws_key_pair.builder_key.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "builder"
  }
}

# ---------------------------------------------------------------- Docker + Docker Compose (Option 2 - bonus)
# remote-exec runs over SSH after the instance is up. Terraform only finishes when the script succeeded.
resource "terraform_data" "install_docker" {
  count = var.install_docker ? 1 : 0

  triggers_replace = [aws_instance.builder.id]

  connection {
    type        = "ssh"
    host        = aws_instance.builder.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.ssh_key.private_key_pem
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait > /dev/null 2>&1 || true", # wait until the first boot finished (apt lock)
      "sudo apt-get update -y",
      "sudo apt-get install -y docker.io docker-compose-v2 git",
      "sudo systemctl enable --now docker",
      "sudo usermod -aG docker ubuntu",
      "sudo docker --version",
      "sudo docker compose version",
      "sudo systemctl is-active docker",
    ]
  }
}
