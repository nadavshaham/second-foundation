# Terraform EKS Cluster Makefile
# Manages staging and production environments with separate workspaces

.PHONY: help init backend setup-workspaces
.PHONY: staging-plan staging-apply staging-destroy staging-output
.PHONY: prod-plan prod-apply prod-destroy prod-output
.PHONY: plan apply destroy output
.PHONY: clean fmt validate workspace-list current-workspace
.PHONY: staging prod

# Default environment (can be overridden)
ENV ?= staging

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Terraform files
STAGING_VARS := staging.tfvars
PROD_VARS := prod.tfvars

##@ Help
help: ## Display this help
	@echo "$(BLUE)Terraform EKS Cluster Management$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make $(YELLOW)<target>$(NC)\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(BLUE)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Setup
init: ## Initialize Terraform
	@echo "$(BLUE)Initializing Terraform...$(NC)"
	terraform init

backend: ## Create AWS backend resources (S3 bucket and DynamoDB table)
	@echo "$(BLUE)Creating Terraform backend resources...$(NC)"
	./create-terraform-backend.sh

setup-workspaces: init ## Create and setup staging and prod workspaces
	@echo "$(BLUE)Setting up Terraform workspaces...$(NC)"
	@terraform workspace new staging 2>/dev/null || echo "$(YELLOW)Staging workspace already exists$(NC)"
	@terraform workspace new prod 2>/dev/null || echo "$(YELLOW)Production workspace already exists$(NC)"
	@echo "$(GREEN)Workspaces created successfully$(NC)"
	@make workspace-list

##@ Staging Environment
staging: ## Switch to staging workspace
	@echo "$(BLUE)Switching to staging workspace...$(NC)"
	terraform workspace select staging
	@echo "$(GREEN)Current workspace: $$(terraform workspace show)$(NC)"

staging-plan: staging ## Plan staging deployment
	@echo "$(BLUE)Planning staging deployment...$(NC)"
	terraform plan -var-file=$(STAGING_VARS) -out=staging.tfplan
	@echo "$(GREEN)Staging plan created: staging.tfplan$(NC)"

staging-apply: staging ## Apply staging deployment
	@echo "$(BLUE)Applying staging deployment...$(NC)"
	@if [ -f staging.tfplan ]; then \
		terraform apply staging.tfplan; \
		rm -f staging.tfplan; \
	else \
		echo "$(YELLOW)No plan file found, running plan and apply...$(NC)"; \
		terraform apply -var-file=$(STAGING_VARS); \
	fi
	@echo "$(GREEN)Staging deployment completed$(NC)"

staging-destroy: staging ## Destroy staging infrastructure
	@echo "$(RED)WARNING: This will destroy staging infrastructure!$(NC)"
	@read -p "Are you sure? Type 'yes' to continue: " confirm && [ "$$confirm" = "yes" ] || (echo "$(BLUE)Operation cancelled$(NC)" && exit 1)
	terraform destroy -var-file=$(STAGING_VARS)
	@echo "$(GREEN)Staging infrastructure destroyed$(NC)"

staging-output: staging ## Show staging outputs
	@echo "$(BLUE)Staging outputs:$(NC)"
	terraform output

##@ Production Environment
prod: ## Switch to production workspace
	@echo "$(BLUE)Switching to production workspace...$(NC)"
	terraform workspace select prod
	@echo "$(GREEN)Current workspace: $$(terraform workspace show)$(NC)"

prod-plan: prod ## Plan production deployment
	@echo "$(BLUE)Planning production deployment...$(NC)"
	terraform plan -var-file=$(PROD_VARS) -out=prod.tfplan
	@echo "$(GREEN)Production plan created: prod.tfplan$(NC)"

prod-apply: prod ## Apply production deployment
	@echo "$(BLUE)Applying production deployment...$(NC)"
	@if [ -f prod.tfplan ]; then \
		terraform apply prod.tfplan; \
		rm -f prod.tfplan; \
	else \
		echo "$(YELLOW)No plan file found, running plan and apply...$(NC)"; \
		terraform apply -var-file=$(PROD_VARS); \
	fi
	@echo "$(GREEN)Production deployment completed$(NC)"

prod-destroy: prod ## Destroy production infrastructure
	@echo "$(RED)WARNING: This will destroy production infrastructure!$(NC)"
	@read -p "Are you sure? Type 'DESTROY' to continue: " confirm && [ "$$confirm" = "DESTROY" ] || (echo "$(BLUE)Operation cancelled$(NC)" && exit 1)
	terraform destroy -var-file=$(PROD_VARS)
	@echo "$(GREEN)Production infrastructure destroyed$(NC)"

prod-output: prod ## Show production outputs
	@echo "$(BLUE)Production outputs:$(NC)"
	terraform output

##@ Generic Commands (use ENV variable)
plan: ## Plan deployment for ENV (default: staging)
	@echo "$(BLUE)Planning $(ENV) deployment...$(NC)"
	terraform workspace select $(ENV)
	@if [ "$(ENV)" = "staging" ]; then \
		terraform plan -var-file=$(STAGING_VARS) -out=$(ENV).tfplan; \
	elif [ "$(ENV)" = "prod" ]; then \
		terraform plan -var-file=$(PROD_VARS) -out=$(ENV).tfplan; \
	else \
		echo "$(RED)Invalid environment: $(ENV). Use 'staging' or 'prod'$(NC)"; \
		exit 1; \
	fi

apply: ## Apply deployment for ENV (default: staging)
	@echo "$(BLUE)Applying $(ENV) deployment...$(NC)"
	terraform workspace select $(ENV)
	@if [ -f $(ENV).tfplan ]; then \
		terraform apply $(ENV).tfplan; \
		rm -f $(ENV).tfplan; \
	else \
		if [ "$(ENV)" = "staging" ]; then \
			terraform apply -var-file=$(STAGING_VARS); \
		elif [ "$(ENV)" = "prod" ]; then \
			terraform apply -var-file=$(PROD_VARS); \
		else \
			echo "$(RED)Invalid environment: $(ENV). Use 'staging' or 'prod'$(NC)"; \
			exit 1; \
		fi \
	fi

destroy: ## Destroy infrastructure for ENV (default: staging)
	@echo "$(RED)WARNING: This will destroy $(ENV) infrastructure!$(NC)"
	terraform workspace select $(ENV)
	@if [ "$(ENV)" = "prod" ]; then \
		read -p "Are you sure? Type 'DESTROY' to continue: " confirm && [ "$$confirm" = "DESTROY" ] || (echo "$(BLUE)Operation cancelled$(NC)" && exit 1); \
	else \
		read -p "Are you sure? Type 'yes' to continue: " confirm && [ "$$confirm" = "yes" ] || (echo "$(BLUE)Operation cancelled$(NC)" && exit 1); \
	fi
	@if [ "$(ENV)" = "staging" ]; then \
		terraform destroy -var-file=$(STAGING_VARS); \
	elif [ "$(ENV)" = "prod" ]; then \
		terraform destroy -var-file=$(PROD_VARS); \
	else \
		echo "$(RED)Invalid environment: $(ENV). Use 'staging' or 'prod'$(NC)"; \
		exit 1; \
	fi

output: ## Show outputs for ENV (default: staging)
	terraform workspace select $(ENV)
	terraform output

##@ Utilities
workspace-list: ## List all workspaces
	@echo "$(BLUE)Available workspaces:$(NC)"
	terraform workspace list

current-workspace: ## Show current workspace
	@echo "$(BLUE)Current workspace:$(NC) $(GREEN)$$(terraform workspace show)$(NC)"

validate: ## Validate Terraform configuration
	@echo "$(BLUE)Validating Terraform configuration...$(NC)"
	terraform validate
	@echo "$(GREEN)Configuration is valid$(NC)"

fmt: ## Format Terraform files
	@echo "$(BLUE)Formatting Terraform files...$(NC)"
	terraform fmt -recursive
	@echo "$(GREEN)Files formatted$(NC)"

clean: ## Clean up plan files and temporary files
	@echo "$(BLUE)Cleaning up temporary files...$(NC)"
	rm -f *.tfplan
	rm -f terraform.tfstate.backup
	@echo "$(GREEN)Cleanup completed$(NC)"

##@ Kubectl Configuration
kubectl-staging: staging-output ## Configure kubectl for staging cluster
	@echo "$(BLUE)Configuring kubectl for staging cluster...$(NC)"
	@CLUSTER_NAME=$$(terraform output -raw cluster_name 2>/dev/null) && \
	REGION=$$(terraform output -raw kubectl_config 2>/dev/null | jq -r '.region') && \
	aws eks update-kubeconfig --region $$REGION --name $$CLUSTER_NAME && \
	echo "$(GREEN)kubectl configured for staging cluster: $$CLUSTER_NAME$(NC)"

kubectl-prod: prod-output ## Configure kubectl for production cluster
	@echo "$(BLUE)Configuring kubectl for production cluster...$(NC)"
	@CLUSTER_NAME=$$(terraform output -raw cluster_name 2>/dev/null) && \
	REGION=$$(terraform output -raw kubectl_config 2>/dev/null | jq -r '.region') && \
	aws eks update-kubeconfig --region $$REGION --name $$CLUSTER_NAME && \
	echo "$(GREEN)kubectl configured for production cluster: $$CLUSTER_NAME$(NC)"

##@ Complete Workflows
deploy-staging: staging-plan staging-apply kubectl-staging ## Complete staging deployment workflow
	@echo "$(GREEN)Staging deployment workflow completed$(NC)"

deploy-prod: prod-plan prod-apply kubectl-prod ## Complete production deployment workflow
	@echo "$(GREEN)Production deployment workflow completed$(NC)"

##@ Infrastructure Status
status: current-workspace ## Show infrastructure status
	@echo "$(BLUE)Infrastructure Status$(NC)"
	@echo "$(BLUE)Current workspace:$(NC) $(GREEN)$$(terraform workspace show)$(NC)"
	@echo ""
	@echo "$(BLUE)Resource Count:$(NC)"
	@terraform state list 2>/dev/null | wc -l | xargs -I {} echo "  {} resources"
	@echo ""
	@echo "$(BLUE)Last Apply:$(NC)"
	@terraform show -json 2>/dev/null | jq -r '.values.root_module.resources[0].values.tags.ManagedBy // "Unknown"' 2>/dev/null || echo "  No state found"