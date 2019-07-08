# circleciからEKSへデプロイするのにつかうimage(.circleci/k8s_ci_image)の保管場所
resource "aws_ecr_repository" "ci_for_k8s" {
  name = "${var.cluster-name}/ci_for_k8s"
}

# app本体のimageの置き場所
resource "aws_ecr_repository" "app" {
  name = "${var.cluster-name}/app"
}
