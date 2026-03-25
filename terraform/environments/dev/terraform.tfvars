# environments/dev/terraform.tfvars
# Commit this file. Secrets (ec2_public_key) injected via CI env vars.

project     = "app"
environment = "dev"
aws_region  = "ap-south-1"

vpc_cidr            = "10.10.0.0/16"
public_subnet_cidrs = ["10.10.1.0/24", "10.10.2.0/24"]
availability_zones  = ["ap-south-1a", "ap-south-1b"]

# Restrict to your office / VPN IP in dev
ssh_allowed_cidrs = ["0.0.0.0/0"]  # tighten for prod

instance_type       = "t3.small"
root_volume_size_gb = 20
