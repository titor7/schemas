# ELBE Infrastructure - Deployment Guide

## Quick Start

This guide will help you deploy the ELBE infrastructure quickly and efficiently.

## Prerequisites

### 1. Install Required Software

```bash
# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Install Ansible
sudo apt update
sudo apt install ansible python3-pip
pip install pywinrm

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### 2. Azure Authentication

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "your-subscription-id"

# Verify access
az account show
```

### 3. Environment Setup

```bash
# Clone the repository
git clone <repository-url>
cd schemas

# Set required environment variables
export TF_VAR_admin_password="YourSecurePassword123!"

# Optional: Create Terraform variables file
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your specific values
```

## Deployment Steps

### Option 1: Automated Deployment (Recommended)

```bash
# Make deploy script executable
chmod +x deploy.sh

# Run full deployment
./deploy.sh deploy
```

### Option 2: Manual Step-by-Step Deployment

#### Step 1: Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

#### Step 2: Configure Servers

```bash
cd ../ansible

# Wait for servers to be ready (usually 5-10 minutes)
sleep 300

# Run configuration playbook
ansible-playbook -i inventories/production.ini playbooks/site.yml
```

#### Step 3: Validate Deployment

```bash
# Test connectivity
ansible -i inventories/production.ini elbe_forest -m ansible.windows.win_ping

# Run validation playbook
ansible-playbook -i inventories/production.ini playbooks/validate-deployment.yml
```

## Post-Deployment Tasks

### 1. Security Configuration

```bash
# Create Ansible vault for passwords
ansible-vault create ansible/group_vars/all/vault.yml

# Add your secure passwords to the vault file:
# vault_admin_password: "YourActualPassword"
# vault_safe_mode_password: "YourSafeModePassword"
# vault_elbe_admin_password: "YourELBEAdminPassword"
# vault_elbe_svc_password: "YourServicePassword"
# vault_local_admin_password: "YourLocalAdminPassword"
```

### 2. Connect to Servers

After deployment, you can connect to your servers using:

- **RDP**: Use the public IP addresses shown in Terraform output
- **PowerShell**: Use WinRM for remote administration
- **Azure Portal**: Access through Azure Serial Console

### 3. Domain Administration

1. Connect to ELBE-N998 (Primary DC)
2. Open "Active Directory Users and Computers"
3. Create additional users and groups as needed
4. Configure Group Policies

### 4. RDS Configuration

1. Connect to ELBE-V981 or ELBE-V982
2. Open "Remote Desktop Services Manager"
3. Configure published applications
4. Set up user access permissions

## Monitoring and Maintenance

### Daily Checks

```bash
# Check infrastructure health
ansible-playbook -i inventories/production.ini playbooks/validate-deployment.yml

# View monitoring logs on admin server (ELBE-V909)
# C:\AdminTools\MonitoringLog.txt
```

### Weekly Tasks

- Review backup logs on ELBE-N998
- Check security event logs
- Verify AD replication status
- Update documentation

### Monthly Tasks

- Apply Windows updates
- Review and update firewall rules
- Test disaster recovery procedures
- Performance optimization

## Troubleshooting

### Common Issues

#### 1. Terraform Apply Fails

```bash
# Check Azure credentials
az account show

# Validate Terraform configuration
terraform validate

# Check for resource conflicts
terraform plan
```

#### 2. Ansible Connection Issues

```bash
# Test WinRM connectivity
ansible -i inventories/production.ini elbe_forest -m ansible.windows.win_ping

# Check server status in Azure
az vm list --resource-group rg-elbe-infrastructure --output table

# Verify network security groups
az network nsg list --resource-group rg-elbe-infrastructure
```

#### 3. Domain Join Failures

```bash
# Check DNS resolution from servers
ansible -i inventories/production.ini elbe_forest -m ansible.windows.win_shell -a "nslookup elbe.its.dnsi"

# Verify domain controller status
ansible -i inventories/production.ini primary_dc -m ansible.windows.win_shell -a "dcdiag"
```

### Log Locations

- **Terraform**: `terraform/terraform.log`
- **Ansible**: `ansible/ansible.log`
- **Windows Event Logs**: Event Viewer on each server
- **Custom Logs**: 
  - Infrastructure monitoring: `C:\AdminTools\MonitoringLog.txt`
  - RDS monitoring: `C:\RDSLogs\RDSMonitoring.txt`
  - Backup logs: `C:\Backups\<date>\`

## Cleanup

To destroy the infrastructure:

```bash
./deploy.sh destroy
```

Or manually:

```bash
cd terraform
terraform destroy
```

## Security Best Practices

1. **Change Default Passwords**: Update all default passwords after deployment
2. **Enable MFA**: Configure multi-factor authentication for admin accounts
3. **Network Segmentation**: Verify VLAN 213 configuration
4. **Regular Updates**: Schedule automatic Windows updates
5. **Backup Verification**: Test restore procedures regularly
6. **Access Control**: Implement least privilege principles
7. **Monitoring**: Set up centralized logging and alerting

## Support

For technical support:

1. Check this documentation and troubleshooting section
2. Review Ansible and Terraform logs
3. Consult Azure documentation for cloud-specific issues
4. Contact your system administrator

## Next Steps

After successful deployment:

1. Customize user accounts and groups
2. Deploy applications on RDS servers
3. Configure additional security policies
4. Set up monitoring and alerting
5. Document any customizations
6. Train users on accessing RDS services