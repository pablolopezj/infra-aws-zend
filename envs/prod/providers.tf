terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "zend-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "mx-central-1"
    dynamodb_table = "zend-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# Provider para us-east-1 (requerido para WAF asociado a CloudFront)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
