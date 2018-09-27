provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
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
  public_key = "${var.public_key}"
}

# data "aws_ami" "debian" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["debian-stretch-hvm-x86_64-gp2-*"]
#   }
  
#   filter {
#     name   = "architecture"
#     values = ["x86_64"]
#   }

#   filter {
#     name   = "block-device-mapping.volume-type"
#     values = ["gp2"]
#   }

#   filter {
#     name   = "ena-support"
#     values = ["true"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   owners = ["679593333241"]
# }

resource "aws_security_group" "ssh" {
  name        = "${var.project_name}-ssh-sg"
  description = "Allow SSH"
  vpc_id      = "${aws_vpc.vpc.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}-ssh-sg"
    )
  )}"
}

resource "aws_instance" "app1" {
  # ami = "${data.aws_ami.debian.id}"
  ami = "ami-0ad001cb48e7f2a56"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.subnet1.id}"
  key_name = "${aws_key_pair.keypair.key_name}"
  vpc_security_group_ids = ["${aws_security_group.ssh.id}"]
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}-app1"
    )
  )}"
}

output "app1_public_ip" {
  value = "${aws_instance.app1.public_ip}"
}