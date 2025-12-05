# Automated Cloud Infrastructure & Configuration Pipeline

## 📋 Project Overview
This project demonstrates a fully automated Infrastructure as Code (IaC) pipeline. It provisions an AWS environment using Terraform and automatically triggers Ansible to configure the server, install Docker, and deploy a web application.

## 🏗 Architecture
- **Terraform**: Provisions VPC, Subnets, Security Groups, and EC2 instances.
- **State Management**: Uses AWS S3 for remote state storage and DynamoDB for state locking (to prevent race conditions in team environments).
- **Local-Exec Hook**: Terraform generates a dynamic inventory file and triggers Ansible.
- **Ansible**: Connects via SSH to the new instance, installs Docker, and runs an Nginx container.

## 🛠 Prerequisites
- Terraform
- Ansible
- AWS CLI
- SSH Key Pair

## ⚙️ Setup & Usage

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/iac-cm-project.git
cd iac-cm-project
````

### 2. Prepare SSH Keys

Generate the keys used for server access:

```bash
ssh-keygen -t rsa -b 2048 -f my-key
chmod 400 my-key
```

### 3. Initialize Terraform

Downloads providers and configures the S3 backend:

```bash
terraform init
```

### 4. Deploy Infrastructure

This command will create the AWS resources and trigger the Ansible playbook:

```bash
terraform apply --auto-approve
```

### 5. Verify Deployment

Once completed, Terraform will output the Server IP. Visit the IP in your browser to see the running Nginx application.

```text
# Example Output
server_ip = "54.123.45.67"
```

## 🧹 Clean Up

To destroy all resources and stop AWS billing:

```bash
terraform destroy --auto-approve
```

