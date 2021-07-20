
terraform {
  required_version = ">= 0.14.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}
provider "aws" {
  profile = "default"
  region  = "us-east-2"
}
resource "aws_instance" "tf_server" {
  ami           = "ami-00399ec92321828f5"
  associate_public_ip_address = var.associate_public_ip_address
  instance_type               = var.ec2_instance_type
  key_name                    = var.ec2_key_name
  monitoring                  = true
  vpc_security_group_ids      = var.vpc_security_group_ids
  user_data = templatefile("${path.module}/userdata.tmpl", {})
  tags = {
    Name = "web-server"
  }
}
