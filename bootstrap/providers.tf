terraform {
  required_version = "~> 1.11"

  # Remote state config
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      Project     = "cedar-summit"
      ManagedBy   = "opentofu"
      Environment = "dev"
    }
  }
}
