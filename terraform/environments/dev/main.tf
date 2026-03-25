###############################################################
# environments/dev/main.tf
###############################################################

terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Repo        = "${var.project}-infra"
  }
}

# ── Networking ────────────────────────────────────────────────
module "networking" {
  source = "../../modules/networking"

  project              = var.project
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  ssh_allowed_cidrs    = var.ssh_allowed_cidrs
  tags                 = local.common_tags
}

# ── Storage ───────────────────────────────────────────────────
module "storage" {
  source      = "../../modules/storage"
  project     = var.project
  environment = var.environment
  tags        = local.common_tags
}

# ── IAM ───────────────────────────────────────────────────────
module "iam" {
  source         = "../../modules/iam"
  project        = var.project
  environment    = var.environment
  app_s3_bucket  = module.storage.bucket_name
  tags           = local.common_tags
}

# ── Compute ───────────────────────────────────────────────────
module "compute" {
  source = "../../modules/compute"

  project               = var.project
  environment           = var.environment
  subnet_id             = module.networking.public_subnet_ids[0]
  security_group_ids    = [module.networking.app_sg_id]
  public_key_material   = var.ec2_public_key
  instance_type         = var.instance_type
  root_volume_size_gb   = var.root_volume_size_gb
  iam_instance_profile  = module.iam.instance_profile_name
  tags                  = local.common_tags
}
