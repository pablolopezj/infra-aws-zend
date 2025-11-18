terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Más adelante puedes activar backend remoto (S3 + DynamoDB) aquí
  # backend "s3" {
  #   bucket = "mi-terraform-state"
  #   key    = "prod/terraform.tfstate"
  #   region = "eu-central-1"
  # }
}

provider "aws" {
  region = var.aws_region
}
