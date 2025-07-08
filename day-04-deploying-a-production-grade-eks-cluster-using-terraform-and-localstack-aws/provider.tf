terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.2.0"
    }
  }
}

provider "aws" {

  region = var.region
  access_key = "test"
  secret_key = "test"
  skip_credentials_validation = true
  skip_metadata_api_check = true
  skip_requesting_account_id = true
  s3_use_path_style = true

  endpoints {
    ec2             = "http://localhost:4566"
    elbv2           = "http://localhost:4566"
    eks             = "http://localhost:4566"
    autoscaling     = "http://localhost:4566"
    iam             = "http://localhost:4566"
    sts             = "http://localhost:4566"
  }

}