terraform {
  required_version = "~> 1.11"

  backend "s3" {
    bucket         = "cedar-summit-tofu"
    key            = "state/infra/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "tofu-statelock-cedar-summit"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
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

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  host                   = module.cedar_summit_eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.cedar_summit_eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.cedar_summit_eks.cluster_name]
  }
}
