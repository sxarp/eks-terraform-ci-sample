resource "aws_s3_bucket" "terraform-backend" {
  bucket = "terraform-backend-for-eks-sxarp"
  acl    = "private"
}
