variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "public_key" {
  description = "Public key for EC2 key pair"
  type        = string
  # Generate with: ssh-keygen -t rsa -b 4096 -f ~/.ssh/latency-monitor
  # Then use: cat ~/.ssh/latency-monitor.pub
}

variable "ssh_allowed_cidr" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict this to your IP for better security
}

variable "docker_image" {
  description = "Docker image for the latency monitor application"
  type        = string
  default     = "lhdung/latency-app:latest"
}
