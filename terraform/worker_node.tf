/* IAM関連
[参考]
https://learn.hashicorp.com/terraform/aws/eks-intro#worker-node-iam-role-and-instance-profile
*/
resource "aws_iam_role" "sample-node" {
  name = "terraform-eks-sample-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "sample-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.sample-node.name}"
}

resource "aws_iam_role_policy_attachment" "sample-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.sample-node.name}"
}

resource "aws_iam_role_policy_attachment" "sample-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.sample-node.name}"
}

resource "aws_iam_instance_profile" "sample-node" {
  name = "terraform-eks-sample"
  role = "${aws_iam_role.sample-node.name}"
}

/* SG関連
[参考]
https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html
*/

resource "aws_security_group" "sample-node" {
  name        = "terraform-eks-sample-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${aws_vpc.sample.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "terraform-eks-sample-node",
     "kubernetes.io/cluster/${var.cluster-name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "sample-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.sample-node.id}"
  source_security_group_id = "${aws_security_group.sample-node.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "sample-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.sample-node.id}"
  source_security_group_id = "${aws_security_group.sample-cluster.id}"
  to_port                  = 65535
  type                     = "ingress"
}
