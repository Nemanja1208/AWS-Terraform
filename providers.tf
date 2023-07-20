terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
    shared_config_files      = ["/Users/neman/.aws/conf"]
    shared_credentials_files = ["/Users/neman/.aws/credentials"]
    profile                  = "nemoPrivateVSCode"
}