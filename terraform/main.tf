terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket         = "aws-lab-tfstate-458781646565"
    key            = "aws-lab/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "aws-lab-tf-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-north-1"
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  my_ip = "${chomp(data.http.my_ip.response_body)}/32"

  ports = {
    22    = "SSH"
    5001  = "Flask app"
    8080  = "Jenkins"
    30443 = "Argo CD"
  }
}

module "network" {
  source = "./modules/network"

  name        = "aws-lab"
  vpc_cidr    = "10.20.0.0/16"
  subnet_cidr = "10.20.1.0/24"
  az          = "eu-north-1a"
}

module "server" {
  source = "./modules/server"

  name          = "aws-lab"
  vpc_id        = module.network.vpc_id
  subnet_id     = module.network.subnet_id
  allowed_cidr  = local.my_ip
  ports         = local.ports
  public_key    = file(pathexpand("~/.ssh/aws-lab.pub"))
  instance_type = "m7i-flex.large"
  user_data     = replace(file("${path.module}/scripts/install.sh"), "\r\n", "\n")
}
