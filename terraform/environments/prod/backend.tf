terraform {
  backend "s3" {
    bucket         = "app-tfstate-<YOUR_ACCOUNT_ID>"
    key            = "prod/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "app-tfstate-lock"
    encrypt        = true
  }
}
