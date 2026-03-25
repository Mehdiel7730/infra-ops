project     = "app"
environment = "prod"
aws_region  = "ap-south-1"

vpc_cidr             = "10.30.0.0/16"
public_subnet_cidrs  = ["10.30.1.0/24", "10.30.2.0/24"]
private_subnet_cidrs = ["10.30.10.0/24", "10.30.11.0/24"]
availability_zones   = ["ap-south-1a", "ap-south-1b"]
ssh_allowed_cidrs    = ["10.0.0.0/8"]
instance_type        = "t3.large"
root_volume_size_gb  = 50
