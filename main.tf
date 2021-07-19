/*terraform {
  required_providers {
    //add additional providers ex. nginx
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  required_version = ">= 0.14.9"
}*/
//nginx details
provider "aws" {
  profile = "default"
  region  = "us-east-2"
}
// reference terraform docs for installing nginx
resource "aws_instance" "tf_server" {
  ami           = "ami-00399ec92321828f5"
  associate_public_ip_address = var.associate_public_ip_address
  instance_type               = var.ec2_instance_type
  key_name                    = var.ec2_key_name
  monitoring                  = true
  vpc_security_group_ids      = var.vpc_security_group_ids
  user_data = templatefile("${path.module}/authdata.tmpl", {})
  tags = {
    Name = "auth-server"
  }
}
resource "aws_instance" "tf_server2" {
  ami           = "ami-00399ec92321828f5"
  associate_public_ip_address = var.associate_public_ip_address
  instance_type               = var.ec2_instance_type
  key_name                    = var.ec2_key_name
  monitoring                  = true
  vpc_security_group_ids      = var.vpc_security_group_ids
#  subnet_id                   = var.vpc_subnet_ids
  user_data = templatefile("${path.module}/userdata.tmpl", {})
  tags = {
    Name = "web-server"
  }
}
