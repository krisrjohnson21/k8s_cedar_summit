terraform {
  required_version = "~> 1.11"

  backend "s3" {
    bucket         = "cedar-summit-tofu"
    key            = "state/restricted/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "tofu-statelock-cedar-summit"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "cedar-summit"
      ManagedBy   = "opentofu"
      Environment = "dev"
    }
  }
}
