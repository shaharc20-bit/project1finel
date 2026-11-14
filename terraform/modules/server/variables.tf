variable "name" {
  type        = string
  description = "Prefix for resource names"
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "allowed_cidr" {
  type        = string
  description = "The only address allowed to reach the open ports"
}

variable "ports" {
  type        = map(string)
  description = "Open ports: port = description"
}

variable "public_key" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "m7i-flex.large"
}

variable "volume_size" {
  type    = number
  default = 30
}

variable "user_data" {
  type        = string
  description = "Install script that runs on first boot"
}
