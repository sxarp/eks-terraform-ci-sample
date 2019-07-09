/* ALB関連
*/
resource "aws_lb" "sample" {
  name               = "eks-sample"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.sample-alb.id}"]
  subnets            = aws_subnet.sample[*].id

  enable_deletion_protection = true

  # access logの有効化を推奨
  # access_logs {
  #   bucket  = "${aws_s3_bucket.sample_alb_log.bucket}"
  #   prefix  = "sample_alb_lb"
  #   enabled = true
  # }

  tags = {
    Environment = "staging"
  }
}

resource "aws_security_group" "sample-alb" {
  name        = "terraform-eks-sample-alb"
  description = "Security group for alb"
  vpc_id      = "${aws_vpc.sample.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "access_to_alb" {
  description              = "Allow aceess to ALB from anywhere"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.sample-alb.id}"
  cidr_blocks              = ["0.0.0.0/0"]
  to_port                  = 65535
  type                     = "ingress"
}
