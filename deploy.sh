#!/bin/bash

# ELBE Infrastructure Deployment Script
# This script deploys the complete ELBE infrastructure using Terraform and Ansible

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    command -v terraform >/dev/null 2>&1 || { print_error "Terraform is required but not installed."; exit 1; }
    command -v ansible >/dev/null 2>&1 || { print_error "Ansible is required but not installed."; exit 1; }
    command -v az >/dev/null 2>&1 || { print_error "Azure CLI is required but not installed."; exit 1; }
    
    print_status "All prerequisites are installed."
}

# Initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    cd terraform
    terraform init
    cd ..
}

# Deploy infrastructure with Terraform
deploy_infrastructure() {
    print_status "Deploying infrastructure with Terraform..."
    cd terraform
    
    # Validate Terraform configuration
    terraform validate
    
    # Plan the deployment
    print_status "Creating Terraform plan..."
    terraform plan -out=tfplan
    
    # Apply the plan
    print_status "Applying Terraform configuration..."
    terraform apply tfplan
    
    # Generate Ansible inventory
    print_status "Generating Ansible inventory..."
    terraform output -raw ansible_inventory > ../ansible/inventories/terraform-generated.ini
    
    cd ..
}

# Configure servers with Ansible
configure_servers() {
    print_status "Configuring servers with Ansible..."
    cd ansible
    
    # Wait for servers to be ready
    print_status "Waiting for servers to be accessible..."
    sleep 120
    
    # Run Ansible playbook
    print_status "Running Ansible playbook..."
    ansible-playbook -i inventories/production.ini playbooks/site.yml -v
    
    cd ..
}

# Validate deployment
validate_deployment() {
    print_status "Validating deployment..."
    cd ansible
    
    # Run validation playbook
    ansible -i inventories/production.ini elbe_forest -m win_ping
    
    print_status "Running post-deployment validation..."
    ansible-playbook -i inventories/production.ini playbooks/validate-deployment.yml
    
    cd ..
}

# Main deployment function
main() {
    print_status "Starting ELBE Infrastructure Deployment..."
    
    # Check if Azure credentials are set
    if ! az account show >/dev/null 2>&1; then
        print_error "Azure credentials not configured. Please run 'az login' first."
        exit 1
    fi
    
    # Check for required environment variables
    if [[ -z "$TF_VAR_admin_password" ]]; then
        print_error "TF_VAR_admin_password environment variable is required."
        exit 1
    fi
    
    check_prerequisites
    init_terraform
    deploy_infrastructure
    configure_servers
    validate_deployment
    
    print_status "ELBE Infrastructure deployment completed successfully!"
    print_status "You can now access your servers using the credentials provided."
    
    # Display connection information
    print_status "Server Information:"
    cd terraform
    terraform output server_details
    cd ..
}

# Help function
show_help() {
    echo "ELBE Infrastructure Deployment Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  deploy     Deploy the complete infrastructure (default)"
    echo "  destroy    Destroy the infrastructure"
    echo "  plan       Show Terraform plan without applying"
    echo "  validate   Validate existing deployment"
    echo "  help       Show this help message"
    echo ""
    echo "Environment Variables Required:"
    echo "  TF_VAR_admin_password    Password for VM administrator account"
    echo ""
    echo "Example:"
    echo "  export TF_VAR_admin_password='YourSecurePassword123!'"
    echo "  $0 deploy"
}

# Destroy infrastructure
destroy_infrastructure() {
    print_warning "This will destroy all ELBE infrastructure!"
    read -p "Are you sure? (yes/no): " -r
    if [[ $REPLY =~ ^yes$ ]]; then
        print_status "Destroying infrastructure..."
        cd terraform
        terraform destroy -auto-approve
        cd ..
        print_status "Infrastructure destroyed."
    else
        print_status "Operation cancelled."
    fi
}

# Plan only
plan_infrastructure() {
    print_status "Creating Terraform plan..."
    cd terraform
    terraform init
    terraform validate
    terraform plan
    cd ..
}

# Handle command line arguments
case "${1:-deploy}" in
    deploy)
        main
        ;;
    destroy)
        destroy_infrastructure
        ;;
    plan)
        check_prerequisites
        plan_infrastructure
        ;;
    validate)
        check_prerequisites
        validate_deployment
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac