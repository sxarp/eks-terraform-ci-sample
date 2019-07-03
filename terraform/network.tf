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

resource "aws_internet_gateway" "sample" {
  vpc_id = "${aws_vpc.sample.id}"

  tags = {
    Name = "terraform-eks-sample"
  }
}

resource "aws_route_table" "sample" {
  vpc_id = "${aws_vpc.sample.id}"
  /*
  このroute tableがassociateされたsubnetはパブリックとなり、インターネットから/へのアクセスが可能となる
  >A subnet that's associated with a route table that has a route to an Internet gateway is known as a public subnet.
  https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenario1.html
  */
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.sample.id}"
  }
}

resource "aws_route_table_association" "sample" {
  count = 2

  subnet_id      = "${aws_subnet.sample.*.id[count.index]}"
  route_table_id = "${aws_route_table.sample.id}"
}
