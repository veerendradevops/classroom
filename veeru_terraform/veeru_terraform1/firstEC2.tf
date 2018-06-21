variable "aws_access_key"
{
default=""
}
variable "aws_secret_key"
{
    default=""
}
variable "region"
{
    default="us-east-1"
}
variable "key"
{
    default="terraform"
}
provider "aws" {
    access_key= "${var.aws_access_key}"
    secret_key= "${var.aws_secret_key}"
    region="${var.region}"
}

resource "aws_instance" "nginx"
{
ami ="ami-a4dc46db"
instance_type = "t2.micro"
key_name= "${var.key}"
security_groups = ["all"]
}
connection
{
    user = "ubuntu"
    private_key = "${var.key}"
}
provisionar "file"
{
    source = "${var.key}"
    destination= "/home/ubuntu/terraform.pem"
}
provisionar "remote-exec"
{
    inline=
    [
        "sudo apt-get update",
        "sudo apt-get install nginx -y",
        "sudo service nginx start"
    ]
}
