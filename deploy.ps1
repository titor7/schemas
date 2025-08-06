# ELBE Infrastructure Deployment Script for Windows
# PowerShell script to deploy ELBE infrastructure

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("deploy", "destroy", "plan", "validate", "help")]
    [string]$Action = "deploy",
    
    [Parameter(Mandatory=$false)]
    [string]$AdminPassword,
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId
)

# Function to write colored output
function Write-Status {
    param([string]$Message, [string]$Color = "Green")
    Write-Host "[INFO] $Message" -ForegroundColor $Color
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-Status "Checking prerequisites..."
    
    # Check Terraform
    try {
        $terraformVersion = terraform version
        Write-Status "Terraform found: $($terraformVersion[0])"
    } catch {
        Write-Error "Terraform is required but not installed. Please install from https://terraform.io"
        exit 1
    }
    
    # Check Azure CLI
    try {
        $azVersion = az version --output tsv --query '"azure-cli"'
        Write-Status "Azure CLI found: $azVersion"
    } catch {
        Write-Error "Azure CLI is required but not installed. Please install from https://docs.microsoft.com/cli/azure/install-azure-cli"
        exit 1
    }
    
    # Check Python/Ansible
    try {
        $ansibleVersion = ansible --version | Select-Object -First 1
        Write-Status "Ansible found: $ansibleVersion"
    } catch {
        Write-Error "Ansible is required but not installed. Please install with: pip install ansible pywinrm"
        exit 1
    }
    
    Write-Status "All prerequisites are installed."
}

# Function to check Azure authentication
function Test-AzureAuth {
    Write-Status "Checking Azure authentication..."
    
    try {
        $account = az account show | ConvertFrom-Json
        Write-Status "Authenticated as: $($account.user.name)"
        Write-Status "Subscription: $($account.name) ($($account.id))"
        
        if ($SubscriptionId -and $account.id -ne $SubscriptionId) {
            Write-Status "Setting subscription to: $SubscriptionId"
            az account set --subscription $SubscriptionId
        }
    } catch {
        Write-Error "Azure authentication failed. Please run 'az login' first."
        exit 1
    }
}

# Function to set environment variables
function Set-Environment {
    if (-not $AdminPassword) {
        $AdminPassword = Read-Host "Enter administrator password" -AsSecureString
        $AdminPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword))
    }
    
    $env:TF_VAR_admin_password = $AdminPassword
    Write-Status "Environment variables set."
}

# Function to initialize Terraform
function Initialize-Terraform {
    Write-Status "Initializing Terraform..."
    Set-Location terraform
    terraform init
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Terraform initialization failed."
        exit 1
    }
    Set-Location ..
}

# Function to deploy infrastructure
function Deploy-Infrastructure {
    Write-Status "Deploying infrastructure with Terraform..."
    Set-Location terraform
    
    # Validate configuration
    terraform validate
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Terraform validation failed."
        exit 1
    }
    
    # Create plan
    Write-Status "Creating Terraform plan..."
    terraform plan -out=tfplan
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Terraform planning failed."
        exit 1
    }
    
    # Apply plan
    Write-Status "Applying Terraform configuration..."
    terraform apply tfplan
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Terraform apply failed."
        exit 1
    }
    
    # Generate Ansible inventory
    Write-Status "Generating Ansible inventory..."
    terraform output -raw ansible_inventory | Out-File -FilePath ..\ansible\inventories\terraform-generated.ini -Encoding UTF8
    
    Set-Location ..
}

# Function to configure servers
function Configure-Servers {
    Write-Status "Configuring servers with Ansible..."
    Set-Location ansible
    
    # Wait for servers to be ready
    Write-Status "Waiting for servers to be accessible..."
    Start-Sleep 120
    
    # Run Ansible playbook
    Write-Status "Running Ansible playbook..."
    ansible-playbook -i inventories/production.ini playbooks/site.yml -v
    
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Ansible playbook completed with warnings. Check the output above."
    }
    
    Set-Location ..
}

# Function to validate deployment
function Test-Deployment {
    Write-Status "Validating deployment..."
    Set-Location ansible
    
    # Test connectivity
    ansible -i inventories/production.ini elbe_forest -m ansible.windows.win_ping
    
    # Run validation playbook
    Write-Status "Running post-deployment validation..."
    ansible-playbook -i inventories/production.ini playbooks/validate-deployment.yml
    
    Set-Location ..
}

# Function to destroy infrastructure
function Remove-Infrastructure {
    Write-Warning "This will destroy all ELBE infrastructure!"
    $confirmation = Read-Host "Are you sure? (yes/no)"
    
    if ($confirmation -eq "yes") {
        Write-Status "Destroying infrastructure..."
        Set-Location terraform
        terraform destroy -auto-approve
        Set-Location ..
        Write-Status "Infrastructure destroyed."
    } else {
        Write-Status "Operation cancelled."
    }
}

# Function to show plan only
function Show-Plan {
    Write-Status "Creating Terraform plan..."
    Set-Location terraform
    terraform init
    terraform validate
    terraform plan
    Set-Location ..
}

# Function to show help
function Show-Help {
    Write-Host @"
ELBE Infrastructure Deployment Script (PowerShell)

Usage: .\deploy.ps1 [-Action <action>] [-AdminPassword <password>] [-SubscriptionId <id>]

Actions:
  deploy     Deploy the complete infrastructure (default)
  destroy    Destroy the infrastructure
  plan       Show Terraform plan without applying
  validate   Validate existing deployment
  help       Show this help message

Parameters:
  -AdminPassword    Password for VM administrator account (will prompt if not provided)
  -SubscriptionId   Azure subscription ID to use

Examples:
  .\deploy.ps1 -Action deploy -AdminPassword "YourSecurePassword123!"
  .\deploy.ps1 -Action plan
  .\deploy.ps1 -Action destroy
"@
}

# Main execution
switch ($Action) {
    "deploy" {
        Write-Status "Starting ELBE Infrastructure Deployment..."
        Test-Prerequisites
        Test-AzureAuth
        Set-Environment
        Initialize-Terraform
        Deploy-Infrastructure
        Configure-Servers
        Test-Deployment
        Write-Status "ELBE Infrastructure deployment completed successfully!"
        
        # Display connection information
        Write-Status "Server Information:"
        Set-Location terraform
        terraform output server_details
        Set-Location ..
    }
    
    "destroy" {
        Remove-Infrastructure
    }
    
    "plan" {
        Test-Prerequisites
        Show-Plan
    }
    
    "validate" {
        Test-Prerequisites
        Test-Deployment
    }
    
    "help" {
        Show-Help
    }
    
    default {
        Write-Error "Unknown action: $Action"
        Show-Help
        exit 1
    }
}