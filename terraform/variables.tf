variable "dockerhub_token" {
  type      = string
  sensitive = true
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "admin password for Jenkins and Argo CD"

  validation {
    condition     = length(var.admin_password) >= 8 && !can(regex("[$'\"\\\\ #=]", var.admin_password))
    error_message = "At least 8 characters, without $ ' \" \\ # = or spaces."
  }
}

variable "gitops_repo" {
  type        = string
  description = "Git repo that Argo CD watches"
  default     = "https://github.com/shaharc20-bit/project1-gitops.git"
}
