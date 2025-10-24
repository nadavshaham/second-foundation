#!/bin/bash

# Script to create AWS S3 bucket and DynamoDB table for Terraform remote state
# This script sets up the backend resources needed for Terraform state management

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
AWS_PAGER=""

echo -e "${BLUE}=== Terraform State Backend Setup ===${NC}"
echo -e "${BLUE}Bucket: ${BUCKET_NAME}${NC}"
echo -e "${BLUE}DynamoDB Table: ${DYNAMODB_TABLE}${NC}"
echo -e "${BLUE}Region: ${REGION}${NC}"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS credentials are not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ AWS CLI is installed and configured${NC}"

# Get current AWS account ID and user
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
USER_ARN=$(aws sts get-caller-identity --query Arn --output text)

echo -e "${BLUE}AWS Account ID: ${ACCOUNT_ID}${NC}"
echo -e "${BLUE}Current User: ${USER_ARN}${NC}"
echo ""

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

# Create S3 bucket for Terraform state
echo -e "${YELLOW}Creating S3 bucket for Terraform state...${NC}"

if check_bucket_exists; then
    echo -e "${YELLOW}⚠ S3 bucket '${BUCKET_NAME}' already exists${NC}"
else
    # Create bucket
    if [ "$REGION" = "us-east-1" ]; then
        # us-east-1 doesn't need LocationConstraint
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$REGION"
    else
        # Other regions need LocationConstraint
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$REGION" \
            --create-bucket-configuration LocationConstraint="$REGION"
    fi
    
    echo -e "${GREEN}✓ S3 bucket '${BUCKET_NAME}' created successfully${NC}"
fi

# Enable versioning on the bucket
echo -e "${YELLOW}Enabling versioning on S3 bucket...${NC}"
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

echo -e "${GREEN}✓ Versioning enabled on S3 bucket${NC}"

# Enable server-side encryption
echo -e "${YELLOW}Enabling server-side encryption on S3 bucket...${NC}"
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                },
                "BucketKeyEnabled": true
            }
        ]
    }'

echo -e "${GREEN}✓ Server-side encryption enabled on S3 bucket${NC}"

# Block public access
echo -e "${YELLOW}Blocking public access to S3 bucket...${NC}"
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo -e "${GREEN}✓ Public access blocked on S3 bucket${NC}"

# Create DynamoDB table for state locking
echo -e "${YELLOW}Creating DynamoDB table for state locking...${NC}"

if check_dynamodb_exists; then
    echo -e "${YELLOW}⚠ DynamoDB table '${DYNAMODB_TABLE}' already exists${NC}"
else
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
        --region "$REGION"
    
    echo -e "${YELLOW}Waiting for DynamoDB table to become active...${NC}"
    aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$REGION"
    
    echo -e "${GREEN}✓ DynamoDB table '${DYNAMODB_TABLE}' created successfully${NC}"
fi

# Add tags to DynamoDB table
echo -e "${YELLOW}Adding tags to DynamoDB table...${NC}"
aws dynamodb tag-resource \
    --resource-arn "arn:aws:dynamodb:${REGION}:${ACCOUNT_ID}:table/${DYNAMODB_TABLE}" \
    --tags Key=Purpose,Value=TerraformStateLock Key=ManagedBy,Value=Script \
    --region "$REGION"

echo -e "${GREEN}✓ Tags added to DynamoDB table${NC}"

echo ""
echo -e "${GREEN}=== Setup Complete! ===${NC}"
echo -e "${GREEN}Your Terraform backend is now ready with the following configuration:${NC}"
echo ""
echo -e "${BLUE}backend \"s3\" {${NC}"
echo -e "${BLUE}  bucket         = \"${BUCKET_NAME}\"${NC}"
echo -e "${BLUE}  key            = \"eks-cluster/terraform.tfstate\"${NC}"
echo -e "${BLUE}  region         = \"${REGION}\"${NC}"
echo -e "${BLUE}  encrypt        = true${NC}"
echo -e "${BLUE}  dynamodb_table = \"${DYNAMODB_TABLE}\"${NC}"
echo -e "${BLUE}}${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "${YELLOW}1. Your versions.tf file is already configured with this backend${NC}"
echo -e "${YELLOW}2. Run 'terraform init' to initialize the backend${NC}"
echo -e "${YELLOW}3. Terraform will ask to migrate existing state (if any)${NC}"
echo ""
echo -e "${GREEN}✓ All resources created successfully!${NC}"