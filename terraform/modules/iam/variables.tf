variable "project"        { type = string }
variable "environment"    { type = string }
variable "app_s3_bucket"  { type = string }
variable "tags"           { type = map(string); default = {} }
