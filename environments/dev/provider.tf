terraform {
  required_version = ">= 1.0.0"

# 以下を追記する
  backend "s3" {
    bucket         = "horikawa"
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.3.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}


