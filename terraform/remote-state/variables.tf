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

variable "state_key" {
  type    = string
  default = "devops-platform/terraform.tfstate"
}

variable "force_destroy" {
  type        = bool
  default     = true
  description = "Allow terraform destroy to empty the bucket (lab account)"
}
