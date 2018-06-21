variable "private_key_path" {}

provider "aws" {
  access_key = ""
  secret_key = ""
  region     = "us-east-1"
}

resource "aws_security_group" "web_server" {
  name        = "web_server"
  description = "used in the terraform"

  #ssh access from anywhere
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "server" {
  ami                    = "ami-a4dc46db"
  instance_type          = "t2.micro"
  key_name               = "terraform"
  vpc_security_group_ids = ["${aws_security_group.web_server.id}"]

  tags {
    name = "server"
  }

  provisioner "remote-exec" {
    connection {
      user        = "ubuntu"
      host        = "${aws_instance.server.public_ip}"
      private_key = "${file(var.private_key_path)}"
    }

    inline = [
      "sudo apt-get update",
      "sudo apt-add-repository ppa:ansible/ansible",
      "sudo apt-get install ansible -y",
      "wget https://github.com/veerendradevops/veerndrarepo/blob/master/nginx.yml",
      "sudo ansible-playbook -i  '${aws_instance.server.public_ip}' nginx.yml",
    ]
  }
}
