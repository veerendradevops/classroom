variable "aws_access_key" {
  default = ""
}

variable "aws_secret_key" {
  default = ""
}

variable "region" {
  default = "us-east-1"
}

variable "securitygroup" {
  default = "allow_all"
}

variable "key" {
  default = "terraform"
}

variable "vpcid" {
  default = "vpc-4baaa230"
}

variable "private_key_path" {}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.region}"
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "allow all inbound traffic"
  vpc_id      = "${var.vpcid}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nginx" {
  ami             = "ami-a4dc46db"
  instance_type   = "t2.micro"
  key_name        = "${var.key}"
  security_groups = ["${var.securitygroup}"]

  connection {
    user        = "ubuntu"
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install nginx -y",
      "sudo service nginx start",
      "sudo apt-get install tomcat7 -y",
      "sudo service tomcat7 start"
    ]
  }
}
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "1.18.0"
  identifier = "demodb"
   engine            = "mysql"
  engine_version    = "5.7.19"
  instance_class    = "db.t2.micro"
  allocated_storage = 5
   name     = "demodb"
  username = "admin"
  password = "admin"
  port     = "3306"
  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"


  vpc_security_group_ids = ["sg-0f2aea6202e9c5a59"]
  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}
