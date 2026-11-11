variable "region" {
  type = string
}

variable "name" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "Empty = default VPC"
}

variable "instance_type" {
  type = string
}

variable "root_volume_size" {
  type = number
}

variable "allowed_cidrs" {
  type = list(string)
}

variable "tcp_ports" {
  type        = map(string)
  description = "port => description, opened to allowed_cidrs"
}

variable "open_nodeport_range" {
  type = bool
}

variable "user_data" {
  type = string
}

variable "ssm_parameter_arns" {
  type = list(string)
}

variable "backup_bucket" {
  type        = string
  description = "Empty = no backup permissions"
}

variable "public_key" {
  type = string
}
