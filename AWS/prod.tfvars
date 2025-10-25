# Production Environment Configuration

# Basic Configuration
cluster_name = "prod"
environment  = "production"
region      = "us-east-1"

# Network Configuration
vpc_cidr               = "10.1.0.0/16"
public_subnet_cidrs    = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs   = ["10.1.3.0/24", "10.1.4.0/24"]

# EKS Configuration
kubernetes_version = "1.32"

# Node Group Configuration - Production sizing
node_instance_types = ["t3.large"]
node_desired_size   = 3
node_max_size       = 6
node_min_size       = 2

# Security Configuration - More restrictive for production
public_access_cidrs = ["0.0.0.0/0"]  # Consider restricting this to your office/VPN CIDR for production

# Tags
tags = {
  Environment = "production"
  Project     = "my-application"
  Owner       = "devops-team"
  CostCenter  = "engineering"
  Backup      = "daily"
  Monitoring  = "enabled"
}