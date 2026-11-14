variable "name" {
  type        = string
  description = "Prefix for resource names"
}

variable "vpc_cidr" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "az" {
  type        = string
  description = "Availability zone of the subnet"
}
