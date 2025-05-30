terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.11.4"
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = "arm_project"
    }
  }
}

locals {
  account_id = data.aws_caller_identity.current.account_id
}
