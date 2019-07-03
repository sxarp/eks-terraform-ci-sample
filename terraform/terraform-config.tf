provider "aws" {
  region = "ap-northeast-1"
  version = "2.16"
}

terraform {
  backend "s3" {
    bucket = "terraform-backend-for-eks-sxarp"
    key    = "terraform"
    region = "ap-northeast-1"

    # tfstateに対してロックを取りつつ一貫性を維持しながら更新をかける
    # Production環境の場合は使用することを推奨
    dynamodb_table = "EKSSampleTfLock"
  }
}
