resource "aws_vpc" "sample" {
  cidr_block = "10.101.0.0/16"

  tags = "${
    map(
     "Name", "terraform-eks-sample-node",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

locals {
  /*
  $ aws ec2 describe-availability-zones --region ap-northeast-1 \
    | jq -r '.AvailabilityZones | map(.ZoneId) | .[]'
  apne1-az4
  apne1-az1
  apne1-az2
  */
  zone_ids = ["apne1-az1","apne1-az2", "apne1-az4"]
}

resource "aws_subnet" "sample" {
  count = 2

  # availability_zone = "${local.zone_ids[count.index]}"
  cidr_block        = "10.101.${count.index}.0/24"
  vpc_id            = "${aws_vpc.sample.id}"

  tags = "${
    map(
     "Name", "terraform-eks-sample-node",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}
