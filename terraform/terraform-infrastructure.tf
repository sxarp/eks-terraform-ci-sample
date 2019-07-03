resource "aws_s3_bucket" "terraform-backend" {
  bucket = "terraform-backend-for-eks-sxarp"
  acl    = "private"
}

resource "aws_dynamodb_table" "eks-sample-lock-table" {
  name           = "EKSSampleTfLock"
  billing_mode   = "PAY_PER_REQUEST"

  # `LockId`ではなく`LockID`なのに注意
  # 参考: https://github.com/hashicorp/terraform/issues/12877#issuecomment-289920798
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
