# EKS Terraform Module

This Terraform module creates an Amazon EKS cluster with a complete VPC infrastructure including:

- VPC with DNS hostname and DNS support enabled
- 2 Public subnets with Internet Gateway
- 2 Private subnets with NAT Gateways (one per AZ for high availability)
- EKS cluster with auto mode enabled
- Managed node group with auto-scaling
- Required IAM roles and policies
- EKS add-ons (VPC CNI, CoreDNS, kube-proxy, EBS CSI driver)

## Features

- **High Availability**: Resources are spread across 2 Availability Zones
- **Auto Scaling**: EKS node group configured with cluster autoscaler tags
- **Security**: Private subnets for worker nodes, public subnets for load balancers
- **Add-ons**: Essential EKS add-ons pre-configured
- **Multi-Environment**: Separate tfvars files for staging and production

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- kubectl (for cluster access after deployment)

## Usage

### 1. Initialize Terraform

```bash
cd AWS
terraform init
```

### 2. Create Terraform Workspaces

Create separate workspaces for staging and production:

```bash
# Create and switch to staging workspace
terraform workspace new staging
terraform workspace select staging

# Create and switch to production workspace
terraform workspace new prod
terraform workspace select prod

# List workspaces
terraform workspace list
```

### 3. Deploy Staging Environment

```bash
# Switch to staging workspace
terraform workspace select staging

# Plan the deployment
terraform plan -var-file="staging.tfvars"

# Apply the configuration
terraform apply -var-file="staging.tfvars"
```

### 4. Deploy Production Environment

```bash
# Switch to production workspace
terraform workspace select prod

# Plan the deployment
terraform plan -var-file="prod.tfvars"

# Apply the configuration
terraform apply -var-file="prod.tfvars"
```

### 5. Configure kubectl

After deployment, configure kubectl to access your cluster:

```bash
# For staging
aws eks update-kubeconfig --region us-west-2 --name my-app-staging

# For production
aws eks update-kubeconfig --region us-west-2 --name my-app-prod
```

### 6. Verify Deployment

```bash
# Check cluster status
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system

# Check cluster info
kubectl cluster-info
```

## Configuration

### Variables

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| cluster_name | Name of the EKS cluster | string | Required |
| environment | Environment name | string | Required |
| region | AWS region | string | us-west-2 |
| vpc_cidr | CIDR block for VPC | string | 10.0.0.0/16 |
| public_subnet_cidrs | CIDR blocks for public subnets | list(string) | ["10.0.1.0/24", "10.0.2.0/24"] |
| private_subnet_cidrs | CIDR blocks for private subnets | list(string) | ["10.0.3.0/24", "10.0.4.0/24"] |
| kubernetes_version | Kubernetes version | string | 1.28 |
| node_instance_types | Instance types for node group | list(string) | ["t3.medium"] |
| node_desired_size | Desired number of nodes | number | 2 |
| node_max_size | Maximum number of nodes | number | 4 |
| node_min_size | Minimum number of nodes | number | 1 |
| public_access_cidrs | CIDRs for public API access | list(string) | ["0.0.0.0/0"] |
| tags | Additional tags | map(string) | {} |

### Environment Files

- `staging.tfvars`: Configuration for staging environment
- `prod.tfvars`: Configuration for production environment

## Outputs

| Output | Description |
|--------|-------------|
| cluster_id | EKS cluster ID |
| cluster_arn | EKS cluster ARN |
| cluster_endpoint | EKS cluster endpoint |
| cluster_name | EKS cluster name |
| vpc_id | VPC ID |
| private_subnet_ids | Private subnet IDs |
| public_subnet_ids | Public subnet IDs |
| kubectl_config | kubectl configuration object |

## Security Considerations

1. **API Server Access**: Consider restricting `public_access_cidrs` to your office/VPN CIDR blocks for production
2. **Node Groups**: Worker nodes are placed in private subnets for security
3. **IAM Roles**: Minimal required permissions are granted to cluster and node group roles
4. **Logging**: EKS control plane logging is enabled for audit and troubleshooting

## Cost Optimization

1. **Instance Types**: Staging uses t3.medium, production uses t3.large
2. **Auto Scaling**: Configured with appropriate min/max sizes for each environment
3. **Spot Instances**: Consider adding spot instances to the node group for cost savings

## Monitoring and Logging

- EKS control plane logs are enabled
- CloudWatch integration available
- Consider adding Prometheus/Grafana for application monitoring

## Cleanup

To destroy resources:

```bash
# Select the appropriate workspace
terraform workspace select staging  # or prod

# Destroy resources
terraform destroy -var-file="staging.tfvars"  # or prod.tfvars
```

## Troubleshooting

### Common Issues

1. **Insufficient Permissions**: Ensure your AWS credentials have the necessary permissions
2. **Resource Limits**: Check AWS service limits for EKS, EC2, and VPC
3. **Subnet Availability**: Ensure you have available IPs in your chosen CIDR ranges

### Useful Commands

```bash
# Check terraform state
terraform state list

# Show specific resource details
terraform state show aws_eks_cluster.main

# Check AWS CLI configuration
aws sts get-caller-identity

# Validate terraform configuration
terraform validate

# Format terraform files
terraform fmt -recursive
```

## Contributing

1. Update variable descriptions and defaults as needed
2. Test changes in staging before applying to production
3. Keep tfvars files updated with environment-specific configurations
4. Update this README when making significant changes

## License

This module is provided under the MIT License.