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
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
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

resource "aws_security_group" "rds_sg" {
  name = "rds-security-group"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "database" {
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  username             = "veeru"
  password             = "veerendra123"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_instance" "server" {
  count                  = "1"
  ami                    = "ami-a4dc46db"
  instance_type          = "t2.micro"
  key_name               = "terraform"
  vpc_security_group_ids = ["${aws_security_group.web_server.id}"]

  tags {
    name = "server"
  }

  provisioner "local-exec" {
    command = "sleep 2m; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key ./terraform.pem -i '${aws_instance.server.public_ip}' php.yml"
  }

  provisioner "remote-exec" {
    connection {
      user        = "ubuntu"
      host        = "${aws_instance.server.public_ip}"
      private_key = "${file(var.private_key_path)}"
    }

    #sed commmand is stream editor for filtering and transforming text
    inline = ["sudo mysql -h ${element(split(":", aws_db_instance.database.endpoint), 0)} -u veeru -p veerendra123 &lt; /var/www/html/db.sql",
      "sudo sed -i 's/192.168.1.10/${element(split(":", aws_db_instance.database.endpoint), 0)}/' /var/www/html/db.properties",
      "sudo sed -i 's/mediauser/veeru/' /var/www/html/db.properties",
      "sudo sed -i 's/Ne0aP1p2PHE9s/veeru/' /var/www/html/db.properties",
      "sudo systemctl restart httpd",
    ]
  }
}

resource "aws_instance" "server1" {
  ami                    = "ami-a4dc46db"
  instance_type          = "t2.micro"
  key_name               = "terraform"
  vpc_security_group_ids = ["${aws_security_group.web_server.id}"]

  tags {
    Name = "server1"
  }

  provisioner "local-exec" {
    command = "sleep 2m; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key ./terraform.pem -i '${aws_instance.server1.public_ip},' php.yml"
  }

  provisioner "remote-exec" {
    connection {
      user        = "ubuntu"
      host        = "${aws_instance.server.public_ip}"
      private_key = "${file(var.private_key_path)}"
    }

    inline = ["sudo mysql -h ${element(split(":", aws_db_instance.database.endpoint), 0)} -u veeru -p veeru &lt; /var/www/html/db.sql",
      "sudo sed -i 's/192.168.1.10/${element(split(":", aws_db_instance.database.endpoint), 0)}/' /var/www/html/db.properties",
      "sudo sed -i 's/mediauser/veeru/' /var/www/html/db.properties",
      "sudo sed -i 's/Ne0aP1p2PHE9s/veeru/' /var/www/html/db.properties",
      "sudo systemctl restart httpd",
    ]
  }
}

resource "aws_elb" "web" {
  name               = "elastic"
  security_groups    = ["${aws_security_group.web_server.id}"]
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = ["${aws_instance.server.id}"]
  instances                   = ["${aws_instance.server1.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "terra-elb"
  }
}
