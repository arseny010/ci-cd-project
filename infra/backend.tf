terraform {
  backend "s3" {
    bucket         = "arseny-tf-state-dev"
    key            = "infra/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}