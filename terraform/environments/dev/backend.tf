terraform {
  backend "s3" {
    bucket         = "app-tfstate-<YOUR_ACCOUNT_ID>"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "app-tfstate-lock"
    encrypt        = true
  }
}
