variable "project"              { type = string; default = "app" }
variable "environment"          { type = string; default = "dev" }
variable "aws_region"           { type = string; default = "ap-south-1" }
variable "vpc_cidr"             { type = string }
variable "public_subnet_cidrs"  { type = list(string) }
variable "private_subnet_cidrs" { type = list(string); default = [] }
variable "availability_zones"   { type = list(string) }
variable "ssh_allowed_cidrs"    { type = list(string) }
variable "ec2_public_key"       { type = string; sensitive = true }
variable "instance_type"        { type = string; default = "t3.small" }
variable "root_volume_size_gb"  { type = number; default = 20 }
