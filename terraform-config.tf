provider "aws" {
  region = "ap-northeast-1"
  version = "2.16"
}

terraform {
  backend "s3" {
    bucket = "terraform-backend-for-eks-sxarp"
    key    = "terraform"
    region = "ap-northeast-1"
  }
}
