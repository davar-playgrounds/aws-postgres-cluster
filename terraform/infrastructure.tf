provider "aws" {
  profile = "${var.profile}"
  region = "${var.region}"
}

resource "aws_vpc" "vpc" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_support = true
  enable_dns_hostnames = true
  instance_tenancy = "default"
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}-vpc"
    )
  )}"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}-igw"
    )
  )}"
}

resource "aws_route_table" "rtb" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}-rtb"
    )
  )}"
}

resource "aws_route" "rt" {
  route_table_id = "${aws_route_table.rtb.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.igw.id}"
}

resource "aws_subnet" "subnet1" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.subnet1_cidr}"
  availability_zone = "${var.region}a"
  map_public_ip_on_launch = true
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}-sn-pub-1"
    )
  )}"
}

resource "aws_route_table_association" "rtb-subnet1" {
  subnet_id = "${aws_subnet.subnet1.id}"
  route_table_id = "${aws_route_table.rtb.id}"
}

resource "aws_subnet" "subnet2" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.subnet2_cidr}"
  availability_zone = "${var.region}b"
  map_public_ip_on_launch = true
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}-sn-pub-2"
    )
  )}"
}

resource "aws_route_table_association" "rtb-subnet2" {
  subnet_id = "${aws_subnet.subnet2.id}"
  route_table_id = "${aws_route_table.rtb.id}"
}

resource "aws_key_pair" "keypair" {
  key_name = "${var.project_name}-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDI1eXRZI5Fm29LU3//R9Mzn4ubNZSI2xm500m6u0YD/ePKSeraWJ0DvBm6uYenEyaB/Iv7koM0i94gwTa7cwMMo+lm7IZJO8OPlfDJp8jmGPGZbjyOGJDwEcAiHvuTRJKG46iC2mbUNyPNANI/ODba0/y/rfYxRSFIFaKt0VEF3L3sxSgE/0dmeiemzRKs8GQGX/qTaxIaY0BI0Q09Jy+MtEK+QJoo99YkeRMSNd7qdn7Cfy8lehfE/X6sS8Bb9Mde3Z6oMpxlzK4lcXA24Mi0kzViDIL7Qv5AAuIfBx1N5Mu6lv7CETLlHLSk32c+zPe/R9qMho7scCV1c81AXGEH dae@gtic-8234m"
}

data "aws_ami" "debian" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-stretch-hvm-x86_64-gp2-*"]
  }
  
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "block-device-mapping.volume-type"
    values = ["gp2"]
  }

  filter {
    name   = "ena-support"
    values = ["true"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"] # Debian
}

resource "aws_instance" "app1" {
  ami           = "${data.aws_ami.debian.id}"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.subnet1.id}"
  key_name = "${aws_key_pair.keypair.key_name}"
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}-app1"
    )
  )}"
}