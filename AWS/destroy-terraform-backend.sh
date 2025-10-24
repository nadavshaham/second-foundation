#!/bin/bash

# Script to destroy AWS S3 bucket and DynamoDB table for Terraform remote state
# WARNING: This will delete all Terraform state files and lock table!

set -e  # Exit on any error

# Configuration
BUCKET_NAME="tf-state-2rsdfgj"
DYNAMODB_TABLE="terraform-state-lock"
REGION="us-east-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}=== WARNING: Terraform State Backend Cleanup ===${NC}"
echo -e "${RED}This will PERMANENTLY DELETE:${NC}"
echo -e "${RED}- S3 bucket: ${BUCKET_NAME} (and ALL contents)${NC}"
echo -e "${RED}- DynamoDB table: ${DYNAMODB_TABLE}${NC}"
echo -e "${RED}- ALL Terraform state files${NC}"
echo ""
echo -e "${YELLOW}This action cannot be undone!${NC}"
echo ""

# Confirmation prompt
read -p "Are you sure you want to proceed? Type 'DELETE' to confirm: " -r
if [[ ! $REPLY == "DELETE" ]]; then
    echo -e "${BLUE}Operation cancelled.${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Starting cleanup...${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed.${NC}"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS credentials are not configured.${NC}"
    exit 1
fi

# Function to check if S3 bucket exists
check_bucket_exists() {
    if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        return 0  # Bucket exists
    else
        return 1  # Bucket doesn't exist
    fi
}

# Function to check if DynamoDB table exists
check_dynamodb_exists() {
    if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$REGION" 2>/dev/null; then
        return 0  # Table exists
    else
        return 1  # Table doesn't exist
    fi
}

# Delete S3 bucket contents and bucket
if check_bucket_exists; then
    echo -e "${YELLOW}Deleting all objects in S3 bucket...${NC}"
    
    # Delete all objects including versions
    aws s3api list-object-versions \
        --bucket "$BUCKET_NAME" \
        --output json \
        --query 'Versions[].{Key:Key,VersionId:VersionId}' | \
    jq -r '.[] | "--key \(.Key) --version-id \(.VersionId)"' | \
    while read -r line; do
        if [ -n "$line" ]; then
            aws s3api delete-object --bucket "$BUCKET_NAME" $line
        fi
    done
    
    # Delete delete markers
    aws s3api list-object-versions \
        --bucket "$BUCKET_NAME" \
        --output json \
        --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' | \
    jq -r '.[] | "--key \(.Key) --version-id \(.VersionId)"' | \
    while read -r line; do
        if [ -n "$line" ]; then
            aws s3api delete-object --bucket "$BUCKET_NAME" $line
        fi
    done
    
    echo -e "${YELLOW}Deleting S3 bucket...${NC}"
    aws s3api delete-bucket --bucket "$BUCKET_NAME" --region "$REGION"
    echo -e "${GREEN}✓ S3 bucket '${BUCKET_NAME}' deleted${NC}"
else
    echo -e "${YELLOW}⚠ S3 bucket '${BUCKET_NAME}' does not exist${NC}"
fi

# Delete DynamoDB table
if check_dynamodb_exists; then
    echo -e "${YELLOW}Deleting DynamoDB table...${NC}"
    aws dynamodb delete-table --table-name "$DYNAMODB_TABLE" --region "$REGION"
    
    echo -e "${YELLOW}Waiting for DynamoDB table to be deleted...${NC}"
    aws dynamodb wait table-not-exists --table-name "$DYNAMODB_TABLE" --region "$REGION"
    echo -e "${GREEN}✓ DynamoDB table '${DYNAMODB_TABLE}' deleted${NC}"
else
    echo -e "${YELLOW}⚠ DynamoDB table '${DYNAMODB_TABLE}' does not exist${NC}"
fi

echo ""
echo -e "${GREEN}=== Cleanup Complete! ===${NC}"
echo -e "${YELLOW}Remember to:${NC}"
echo -e "${YELLOW}1. Comment out the backend configuration in versions.tf${NC}"
echo -e "${YELLOW}2. Run 'terraform init' to reinitialize with local state${NC}"
echo -e "${YELLOW}3. Or migrate to a different backend if needed${NC}"
echo ""
echo -e "${RED}⚠ All Terraform state has been permanently deleted!${NC}"