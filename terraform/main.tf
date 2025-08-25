# LEGACY FILE - MIGRATED TO MODULAR STRUCTURE
# 
# This file has been replaced by the new modular architecture.
# Please use the environment-specific configurations instead:
#
# - Development: terraform/environments/dev/
# - Staging:     terraform/environments/staging/
# - Production:  terraform/environments/prod/
#
# See MIGRATION.md for migration instructions.
#
# AWS Provider Configuration (LEGACY)
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

# Data source for latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "latency-monitor-vpc"
    Environment = var.environment
    Project     = "latency-monitoring"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "latency-monitor-igw"
    Environment = var.environment
  }
}

# Create public subnets in different AZs
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "latency-monitor-public-subnet-a"
    Environment = var.environment
    Type        = "Public"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name        = "latency-monitor-public-subnet-b"
    Environment = var.environment
    Type        = "Public"
  }
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Create route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "latency-monitor-public-rt"
    Environment = var.environment
  }
}

# Associate route table with public subnets
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Security Group for Latency Monitor Server
resource "aws_security_group" "latency_monitor" {
  name_prefix = "latency-monitor-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for latency monitoring application"

  # HTTP access to FastAPI app
  ingress {
    description = "FastAPI HTTP"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidr
  }

  # All outbound traffic
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "latency-monitor-sg"
    Environment = var.environment
  }
}

# Security Group for Target Server
resource "aws_security_group" "target_server" {
  name_prefix = "target-server-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for target server"

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidr
  }

  # All outbound traffic
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "target-server-sg"
    Environment = var.environment
  }
}

# Key pair for EC2 instances
resource "aws_key_pair" "main" {
  key_name   = "latency-monitor-key"
  public_key = var.public_key

  tags = {
    Name        = "latency-monitor-keypair"
    Environment = var.environment
  }
}

# Elastic IPs
resource "aws_eip" "latency_monitor" {
  domain = "vpc"
  tags = {
    Name        = "latency-monitor-eip"
    Environment = var.environment
  }
}

resource "aws_eip" "target_server" {
  domain = "vpc"
  tags = {
    Name        = "target-server-eip"
    Environment = var.environment
  }
}

# EC2 Instance for Target Server (deploy first)
resource "aws_instance" "target_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.main.key_name
  subnet_id     = aws_subnet.public_b.id

  vpc_security_group_ids = [aws_security_group.target_server.id]

  user_data = base64encode(file("${path.module}/user_data_target.sh"))

  tags = {
    Name        = "target-server"
    Environment = var.environment
    Role        = "TargetServer"
  }
}

# Associate Elastic IP for Target Server
resource "aws_eip_association" "target_server" {
  instance_id   = aws_instance.target_server.id
  allocation_id = aws_eip.target_server.id
}

# EC2 Instance for Latency Monitor (deploy after target server)
resource "aws_instance" "latency_monitor" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.main.key_name
  subnet_id     = aws_subnet.public_a.id

  vpc_security_group_ids = [aws_security_group.latency_monitor.id]

  user_data = base64encode(templatefile("${path.module}/user_data_monitor.sh", {
    target_host = aws_eip.target_server.public_ip
    target_port = 80
    docker_image = var.docker_image
  }))

  tags = {
    Name        = "latency-monitor-server"
    Environment = var.environment
    Role        = "LatencyMonitor"
  }

  depends_on = [aws_eip_association.target_server]
}

# Associate Elastic IP for Latency Monitor
resource "aws_eip_association" "latency_monitor" {
  instance_id   = aws_instance.latency_monitor.id
  allocation_id = aws_eip.latency_monitor.id
}
