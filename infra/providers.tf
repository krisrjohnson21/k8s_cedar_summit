terraform {
  required_version = "~> 1.11"

  # Remote state config
  backend "s3" {
    bucket         = "cedar-summit-tofu"
    key            = "state/aws-base/terraform.tfstate"
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
  profile = "krj-personal"

  default_tags {
    tags = {
      Project     = "cedar-summit"
      ManagedBy   = "opentofu"
      Environment = "dev"
    }
  }
}
