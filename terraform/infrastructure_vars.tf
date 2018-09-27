variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "region" {
  default = "eu-west-1"
}

variable "public_key" {}

variable "project_name" {
  default = "aws-pg-cls"
}

variable "vpc_cidr" {
  default = "10.10.0.0/16"
}

variable "subnet1_cidr" {
  default = "10.10.0.0/24"
}

variable "subnet2_cidr" {
  default = "10.10.1.0/24"
}

locals {
  ami = "ami-0ad001cb48e7f2a56"
}


locals {
  common_tags = {
    Project = "${var.project_name}"
  }
}
