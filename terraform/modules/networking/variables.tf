variable "project"     { type = string }
variable "environment" { type = string }
variable "vpc_cidr"    { type = string }

variable "public_subnet_cidrs" {
  type    = list(string)
  default = []
}
variable "private_subnet_cidrs" {
  type    = list(string)
  default = []
}
variable "availability_zones" {
  type    = list(string)
  default = []
}
variable "ssh_allowed_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to SSH. Restrict to your office/VPN IP."
  default     = ["0.0.0.0/0"]
}
variable "tags" {
  type    = map(string)
  default = {}
}
