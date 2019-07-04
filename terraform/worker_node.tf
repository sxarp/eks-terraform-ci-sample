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

/* AutoScaling Group関連
[参考]
https://learn.hashicorp.com/terraform/aws/eks-intro#worker-node-autoscaling-group
*/

# 参考: https://github.com/awslabs/amazon-eks-ami/blob/master/files/bootstrap.sh
locals {
  sample-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.sample.endpoint}' --b64-cluster-ca '${aws_eks_cluster.sample.certificate_authority.0.data}' '${var.cluster-name}'
USERDATA
}

resource "aws_launch_configuration" "sample" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.sample-node.name}"

  /* image_idの選び方
  Kubernetesのversion:
  ```
  $ kubectl version -o json | jq '.serverVersion.minor'
  "12+"
  ```

  Tokyoリージョンの1.12.*でGPUのサポートなしを[https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html]から選ぶ
  */
  image_id                    = "ami-0a9b3f8b4b65b402b"

  /*
  インスタンスタイプはネットワークの性能保証があるm4系がオススメ
  ネットワークが遅いとimageのpullに異常に時間がかかることがあるので
  参考: https://aws.amazon.com/ec2/instance-types/
  */
  instance_type               = "m4.large"

  name_prefix                 = "terraform-eks-sample"
  security_groups             = ["${aws_security_group.sample-node.id}"]
  user_data_base64            = "${base64encode(local.sample-node-userdata)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "sample" {
  desired_capacity     = 2
  launch_configuration = "${aws_launch_configuration.sample.id}"
  max_size             = 2
  min_size             = 1
  name                 = "terraform-eks-sample"
  vpc_zone_identifier  = aws_subnet.sample[*].id

  tag {
    key                 = "Name"
    value               = "terraform-eks-sample"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
}

/* worker nodesをクラスターに参加させるConfigMap
以下で取得可能:
$ terraform output config_map_aws_auth
[参考]
https://learn.hashicorp.com/terraform/aws/eks-intro#required-kubernetes-configuration-to-join-worker-nodes
*/
locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.sample-node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH
}

output "config_map_aws_auth" {
  value = "${local.config_map_aws_auth}"
}
