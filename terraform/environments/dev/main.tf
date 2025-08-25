# Simple Development Environment
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Use the simple main configuration from root level
module "simple_deployment" {
  source = "../../"

  aws_region       = var.aws_region
  environment      = "dev"
  public_key       = var.public_key
  ssh_allowed_cidr = var.ssh_allowed_cidr
  docker_image     = var.docker_image
  instance_type    = "t3.micro"
}