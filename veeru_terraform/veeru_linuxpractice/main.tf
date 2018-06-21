variable "access_key"{
default=""
}
variable "secret_key"{
default= ""
}
variable "ami"{
    default = "ami-a4dc46db"
}
variable "instance_type"{
    default="t2.micro"
}
variable "region"{
    default="us-east-1"
}
provider "aws"
{
    access_key="${var.access_key}"
    secret_key="${var.secret_key}"
    region= "${var.region}"

}
resource "aws_instance" "linux_practice"
{
    ami="${var.ami}"
    instance_type= "${var.instance_type}"
    key_name="terraform"

}