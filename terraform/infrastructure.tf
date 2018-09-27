provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.region}"
}

resource "aws_vpc" "main" {
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

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}-igw"
    )
  )}"
}

resource "aws_route_table" "main" {
  vpc_id = "${aws_vpc.main.id}"
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}-rtb"
    )
  )}"
}

resource "aws_route" "default" {
  route_table_id = "${aws_route_table.main.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.main.id}"
}

resource "aws_subnet" "public-a" {
  vpc_id = "${aws_vpc.main.id}"
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

resource "aws_route_table_association" "public-a" {
  subnet_id = "${aws_subnet.public-a.id}"
  route_table_id = "${aws_route_table.main.id}"
}

resource "aws_subnet" "public-b" {
  vpc_id = "${aws_vpc.main.id}"
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

resource "aws_route_table_association" "public-b" {
  subnet_id = "${aws_subnet.public-b.id}"
  route_table_id = "${aws_route_table.main.id}"
}

resource "aws_key_pair" "default" {
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
  description = "Open SSH port"
  vpc_id      = "${aws_vpc.main.id}"
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

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Open APP ports e.g. 80"
  vpc_id      = "${aws_vpc.main.id}"
  ingress {
    from_port   = 80
    to_port     = 80
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
      "Name", "${var.project_name}-app-sg"
    )
  )}"
}

resource "aws_instance" "app" {
  # ami = "${data.aws_ami.debian.id}"
  ami = "${local.ami}"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public-a.id}"
  key_name = "${aws_key_pair.default.key_name}"
  vpc_security_group_ids = ["${aws_security_group.ssh.id}", "${aws_security_group.app.id}"]
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}-app"
    )
  )}"
}

resource "aws_instance" "db-master" {
  # ami = "${data.aws_ami.debian.id}"
  ami = "${local.ami}"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public-a.id}"
  key_name = "${aws_key_pair.default.key_name}"
  vpc_security_group_ids = ["${aws_security_group.ssh.id}"]
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}-db-master"
    )
  )}"
}

resource "aws_instance" "db-slave" {
  # ami = "${data.aws_ami.debian.id}"
  ami = "${local.ami}"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public-b.id}"
  key_name = "${aws_key_pair.default.key_name}"
  vpc_security_group_ids = ["${aws_security_group.ssh.id}"]
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}-db-slave"
    )
  )}"
}

output "app-public-ip" {
  value = "${aws_instance.app.public_ip}"
}

output "db-master-public-ip" {
  value = "${aws_instance.db-master.public_ip}"
}

output "db-slave-public-ip" {
  value = "${aws_instance.db-slave.public_ip}"
}

output "app-private-ip" {
  value = "${aws_instance.app.private_ip}"
}

output "db-master-private-ip" {
  value = "${aws_instance.db-master.private_ip}"
}

output "db-slave-private-ip" {
  value = "${aws_instance.db-slave.private_ip}"
}