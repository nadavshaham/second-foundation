# Staging Environment Configuration

# Basic Configuration
cluster_name = "staging"
environment  = "staging"
region      = "us-east-1"

# Network Configuration
vpc_cidr               = "10.0.0.0/16"
public_subnet_cidrs    = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs   = ["10.0.3.0/24", "10.0.4.0/24"]

# EKS Configuration
kubernetes_version = "1.28"

# Node Group Configuration
node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_max_size       = 3
node_min_size       = 1

# Security Configuration
public_access_cidrs = ["0.0.0.0/0"]  # Consider restricting this to your office/VPN CIDR

# Tags
tags = {
  Environment = "staging"
  Project     = "my-application"
  Owner       = "devops-team"
  CostCenter  = "engineering"
}