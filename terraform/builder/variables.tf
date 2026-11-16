variable "region" {
  type        = string
  default     = "us-east-1"
  description = "Exam region"
}

variable "vpc_id" {
  type        = string
  default     = "vpc-044604d0bfb707142"
  description = "The existing VPC given by the instructor (do NOT create a new VPC)"
}

variable "subnet_id" {
  type        = string
  default     = ""
  description = "Optional: a public subnet of the VPC. Empty = the first public subnet found"
}

variable "instance_type" {
  type        = string
  default     = "t3.medium"
  description = "t3.medium is enough for Docker + Jenkins"
}

variable "my_ip_cidr" {
  type        = string
  default     = ""
  description = "Optional: x.x.x.x/32. Empty = detected automatically with checkip.amazonaws.com"
}

variable "install_docker" {
  type        = bool
  default     = true
  description = "Install Docker + Docker Compose with remote-exec (bonus). false = install manually over SSH (Option 1)"
}
