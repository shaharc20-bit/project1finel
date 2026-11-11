variable "region" {
  type    = string
  default = "eu-north-1"
}

variable "project" {
  type    = string
  default = "devops-platform"
}

variable "owner" {
  type    = string
  default = "shahar"
}

variable "vpc_id" {
  type        = string
  default     = "vpc-0a318c6ec12295c3c"
  description = "Empty = default VPC of the account"
}

variable "instance_type" {
  type        = string
  default     = "m7i-flex.large"
  description = "Free Tier eligible, 2 vCPU / 8GB: Jenkins + k3s + Argo CD"
}

variable "root_volume_size" {
  type    = number
  default = 30
}

variable "allowed_cidrs" {
  type        = list(string)
  default     = []
  description = "Your home IP, e.g. [\"1.2.3.4/32\"]. The IP running terraform is added automatically"
}

variable "ssh_public_key_path" {
  type    = string
  default = "ssh/mykey.pub"
}

variable "ssh_private_key_path" {
  type    = string
  default = "ssh/mykey"
}

variable "detect_my_ip" {
  type    = bool
  default = true
}

variable "repo_url" {
  type        = string
  default     = "https://github.com/shaharc20-bit/project1finel.git"
  description = "Repo with code/ (CI) and gitops/ (Argo CD)"
}

variable "repo_branch" {
  type    = string
  default = "main"
}

variable "github_username" {
  type    = string
  default = "shaharc20-bit"
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "GitHub token (repo scope): Jenkins pushes rendered manifests to gitops/, Argo CD reads the repo"
}

variable "dockerhub_username" {
  type    = string
  default = "shaharc20"
}

variable "dockerhub_token" {
  type        = string
  sensitive   = true
  description = "Docker Hub access token (Read & Write), used by Jenkins to push the image"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Password of the 'admin' user in Jenkins and Argo CD"

  validation {
    condition     = length(var.admin_password) >= 8 && !can(regex("[$'\"\\\\ ]", var.admin_password))
    error_message = "admin_password: at least 8 characters, without $, quotes, backslash or spaces."
  }
}

variable "backup_bucket" {
  type        = string
  default     = ""
  description = "Set by remote-state/ (remote-state.auto.tfvars). Jenkins is backed up there daily"
}

variable "trigger_first_build" {
  type    = bool
  default = true
}
