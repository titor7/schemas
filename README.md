# ELBE Infrastructure Documentation

## Overview

This project implements a complete Ansible and Terraform infrastructure for deploying and configuring the 5 ELBE servers as identified in the `infomil-ad-siadmin.drawio` diagram.

## Architecture

### Servers

1. **ELBE-N998** (179.105.12.98/27)
   - Primary Domain Controller of the elbe.its.dnsi forest
   - Hosts administrative accounts for the entire infrastructure
   - Enhanced security with latest standards and best practices
   - VLAN 213 ([z2] intranet-elbe)

2. **ELBE-N999** (179.105.12.99/27)
   - Secondary Domain Controller of the elbe.its.dnsi forest
   - VLAN 213 ([z2] intranet-elbe)

3. **ELBE-V909** (179.105.13.9/24)
   - Administration server for all servers in the elbe.its.dnsi forest
   - VLAN 213 ([z2] intranet-elbe)

4. **ELBE-V981** (179.105.13.81/24)
   - RDS farm server
   - VLAN 213 ([z2] intranet-elbe)

5. **ELBE-V982** (179.105.13.82/24)
   - RDS farm server (Note: IP corrected from duplicate 179.105.13.81)
   - VLAN 213 ([z2] intranet-elbe)

### Network Ports and Services

The infrastructure configures the following ports and services:

- **Kerberos**: tcp/88, udp/88
- **NTP**: tcp/123, udp/123
- **RPC**: tcp/135, udp/135
- **SMB**: tcp/445, udp/445
- **Kerberos change password**: tcp/464, udp/464
- **LDAPS**: tcp/636, udp/636
- **Global Catalog SSL**: tcp/3269, udp/3269
- **WinRM**: tcp/5985
- **ADWS**: tcp/9389
- **RPC dynamic range**: tcp/49152-65535

## Prerequisites

### Software Requirements

- Terraform >= 1.0
- Ansible >= 2.9 with WinRM support
- Azure CLI
- Python 3.6+
- pywinrm library

### Azure Setup

1. Install Azure CLI
2. Login to Azure: `az login`
3. Set subscription: `az account set --subscription "your-subscription-id"`

### Environment Variables

Set the following environment variables before deployment:

```bash
export TF_VAR_admin_password="YourSecurePassword123!"
export ANSIBLE_VAULT_PASSWORD_FILE=.vault_pass
```

## Deployment

### Quick Deployment

```bash
# Clone the repository
git clone <repository-url>
cd schemas

# Set required environment variables
export TF_VAR_admin_password="YourSecurePassword123!"

# Run deployment
./deploy.sh deploy
```

### Manual Deployment

#### 1. Deploy Infrastructure with Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

#### 2. Configure Servers with Ansible

```bash
cd ../ansible
ansible-playbook -i inventories/production.ini playbooks/site.yml
```

#### 3. Validate Deployment

```bash
ansible-playbook -i inventories/production.ini playbooks/validate-deployment.yml
```

## Project Structure

```
├── ansible/
│   ├── ansible.cfg                    # Ansible configuration
│   ├── inventories/
│   │   └── production.ini             # Production inventory
│   ├── playbooks/
│   │   ├── deploy-elbe-infrastructure.yml
│   │   ├── site.yml                   # Main site playbook
│   │   └── validate-deployment.yml    # Validation playbook
│   ├── roles/
│   │   ├── common-windows/            # Common Windows configuration
│   │   ├── domain-controller/         # Domain controller setup
│   │   ├── admin-server/              # Administration server
│   │   └── rds-server/                # RDS server configuration
│   └── group_vars/
│       ├── elbe_forest.yml           # Forest-wide variables
│       └── domain_controllers.yml    # DC-specific variables
├── terraform/
│   ├── main.tf                       # Main Terraform configuration
│   ├── variables.tf                  # Variable definitions
│   ├── outputs.tf                    # Output definitions
│   ├── modules/
│   │   └── windows-server/           # Windows server module
│   └── templates/
│       └── inventory.tpl             # Ansible inventory template
├── deploy.sh                         # Deployment script
└── README.md                         # This documentation
```

## Configuration Details

### Domain Configuration

- **Domain Name**: elbe.its.dnsi
- **NetBIOS Name**: ELBE
- **Functional Level**: Windows Server 2016
- **DNS Forwarders**: 8.8.8.8, 8.8.4.4

### Security Configuration

- Password complexity enabled
- Account lockout after 5 failed attempts
- Minimum password length: 12 characters
- Password history: 24 passwords
- Windows Defender enabled
- Windows Firewall enabled on all profiles
- Latest security updates applied

### Backup Strategy

- Daily system state backups
- SYSVOL replication monitoring
- Active Directory health checks
- Automated cleanup of old backups (7-day retention)

## Management and Monitoring

### Administration Server (ELBE-V909)

The administration server provides:

- RSAT tools for domain management
- PowerShell modules for AD administration
- Monitoring scripts for infrastructure health
- User management utilities
- Network documentation generation

### Monitoring Scripts

1. **Infrastructure Monitoring**: Checks server availability and AD replication
2. **RDS Monitoring**: Monitors RDS services and active sessions
3. **Backup Monitoring**: Validates backup completion and integrity

## Troubleshooting

### Common Issues

1. **WinRM Connection Failures**
   - Verify WinRM service is running
   - Check firewall rules for port 5985
   - Validate credentials and authentication

2. **Domain Join Failures**
   - Ensure DNS resolution works
   - Verify domain controller accessibility
   - Check domain credentials

3. **RDS Configuration Issues**
   - Verify RDS services are running
   - Check RDS licensing configuration
   - Validate session host settings

### Log Locations

- Ansible logs: `ansible/ansible.log`
- Infrastructure monitoring: `C:\AdminTools\MonitoringLog.txt` (on ELBE-V909)
- RDS monitoring: `C:\RDSLogs\RDSMonitoring.txt` (on RDS servers)
- Backup logs: `C:\Backups\<date>\` (on ELBE-N998)

## Security Considerations

### Best Practices Implemented

1. **Network Security**
   - Network segmentation with VLANs
   - Firewall rules for required services only
   - Secure communication protocols (LDAPS, etc.)

2. **Identity and Access Management**
   - Strong password policies
   - Account lockout protection
   - Privileged account management

3. **System Hardening**
   - Latest security updates
   - Windows Defender configuration
   - Registry security settings
   - Service hardening

4. **Monitoring and Logging**
   - Security event logging
   - Failed logon detection
   - System health monitoring

## Maintenance

### Regular Tasks

1. **Weekly**
   - Review monitoring logs
   - Check backup status
   - Verify AD replication health

2. **Monthly**
   - Update documentation
   - Review security logs
   - Test disaster recovery procedures

3. **Quarterly**
   - Security assessment
   - Performance optimization
   - Capacity planning review

## Support

For issues and questions:

1. Check the troubleshooting section
2. Review Ansible and Terraform logs
3. Validate network connectivity
4. Consult Azure documentation for cloud-specific issues

## License

This project follows the organization's standard licensing terms.