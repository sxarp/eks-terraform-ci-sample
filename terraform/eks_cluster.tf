/* IAM関連
[参考]
https://learn.hashicorp.com/terraform/aws/eks-intro#eks-master-cluster-iam-role
*/
resource "aws_iam_role" "sample-cluster" {
  name = "terraform-eks-sample-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "sample-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.sample-cluster.name}"
}

resource "aws_iam_role_policy_attachment" "sample-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.sample-cluster.name}"
}


/* SG関連
worker nodeからの通信を許可する
[参考]
https://learn.hashicorp.com/terraform/aws/eks-intro#eks-master-cluster-security-group
https://learn.hashicorp.com/terraform/aws/eks-intro#worker-node-access-to-eks-master-cluster
*/

resource "aws_security_group" "sample-cluster" {
  name        = "terraform-eks-sample-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${aws_vpc.sample.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-eks-sample"
  }
}

resource "aws_security_group_rule" "sample-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.sample-cluster.id}"
  source_security_group_id = "${aws_security_group.sample-node.id}"
  to_port                  = 443
  type                     = "ingress"
}

# TODO: 必要性を検証
resource "aws_security_group_rule" "sample-cluster-ingress-workstation-https" {
  cidr_blocks       = ["111.108.8.42/32"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.sample-cluster.id}"
  to_port           = 443
  type              = "ingress"
}

/* クラスタ本体
高いので使ってない時は消しておく
[参考]
https://learn.hashicorp.com/terraform/aws/eks-intro#eks-master-cluster
*/
resource "aws_eks_cluster" "sample" {
  name            = "${var.cluster-name}"
  role_arn        = "${aws_iam_role.sample-cluster.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.sample-cluster.id}"]
    subnet_ids         = aws_subnet.sample[*].id
  }

  depends_on = [
    "aws_iam_role_policy_attachment.sample-cluster-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.sample-cluster-AmazonEKSServicePolicy",
  ]
}
