provider "aws" {
  region = var.region

  default_tags {
    tags = merge(var.tags, {
      Environment   = var.environment
      ManagedBy    = "Terraform"
      ClusterName  = var.cluster_name
    })
  }
}