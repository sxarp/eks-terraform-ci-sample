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

resource "aws_lb_listener" "sample" {
  load_balancer_arn = "${aws_lb.sample.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.sample.arn}"
  }
}

/* SG関連
*/
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

resource "aws_security_group_rule" "access-to-alb" {
  description              = "Allow aceess to ALB from anywhere"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.sample-alb.id}"
  cidr_blocks              = ["0.0.0.0/0"]
  to_port                  = 65535
  type                     = "ingress"
}

/* TG関連
*/
resource "aws_alb_target_group" "sample" {
  name     = "sample-target-group"
  port     = 30001
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.sample.id}"

  health_check {
    path = "/health"
  }
}

resource "aws_autoscaling_attachment" "sample" {
  autoscaling_group_name = "${aws_autoscaling_group.sample.id}"
  alb_target_group_arn   = "${aws_alb_target_group.sample.arn}"
}
