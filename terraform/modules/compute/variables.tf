variable "project"               { type = string }
variable "environment"           { type = string }
variable "subnet_id"             { type = string }
variable "security_group_ids"    { type = list(string) }
variable "public_key_material"   { type = string }
variable "instance_type"         { type = string; default = "t3.medium" }
variable "root_volume_size_gb"   { type = number; default = 30 }
variable "iam_instance_profile"  { type = string; default = null }
variable "tags"                  { type = map(string); default = {} }
