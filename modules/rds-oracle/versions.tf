terraform {
  required_version = ">= 1.0.0"
  required_providers {
    local = {
      source = "hashicorp/local"
      version = "2.1.0"
    }
    random = {
      source = "hashicorp/random"
      version = "3.1.0"
    }
    template = {
      source = "hashicorp/template"
      version = "2.2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.49.0"
    }
  }
  backend "s3" {}
}