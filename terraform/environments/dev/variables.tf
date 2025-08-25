# Simple Development Environment Variables

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "public_key" {
  description = "Public key for EC2 key pair"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "docker_image" {
  description = "Docker image for the latency monitor application"
  type        = string
  default     = "lhdung/latency-app:latest"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "lhdung"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "lhdung"
}