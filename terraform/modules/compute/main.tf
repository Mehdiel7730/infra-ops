###############################################################
# modules/compute/main.tf
# Resources: Key pair · EC2 instance · Elastic IP
###############################################################

locals {
  name_prefix = "${var.project}-${var.environment}"
}

# ── SSH Key Pair ──────────────────────────────────────────────
resource "aws_key_pair" "this" {
  key_name   = "${local.name_prefix}-key"
  public_key = var.public_key_material

  tags = var.tags
}

# ── Latest Ubuntu 24.04 LTS AMI ───────────────────────────────
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── EC2 Instance ──────────────────────────────────────────────
resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.this.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = var.iam_instance_profile

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size_gb
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_tokens   = "required"   # IMDSv2 only
    http_endpoint = "enabled"
  }

  user_data = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname ${local.name_prefix}-server
    echo "127.0.0.1 ${local.name_prefix}-server" >> /etc/hosts
  EOF

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-server"
  })

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

# ── Elastic IP ────────────────────────────────────────────────
resource "aws_eip" "app" {
  instance = aws_instance.app.id
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-eip"
  })
}
