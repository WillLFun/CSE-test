terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"

}

provider "aws" {
  profile = "default"
  region  = "us-east-2"
}

resource "aws_instance" "web_server" {
  ami           = "ami-00399ec92321828f5"
  associate_public_ip_address = var.associate_public_ip_address
  instance_type               = var.ec2_instance_type
  key_name                    = var.ec2_key_name
  monitoring                  = true
  vpc_security_group_ids      = var.vpc_security_group_ids
  /*user_data = templatefile("${path.module}/userdata.tmpl", {})*/
  tags = {
    Name = "wireguard-nginx"
  }

  provisioner "remote-exec" {
   inline = [
     # Prevents timing conflict between cloud-init and the package installations
     "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
     "sudo apt-get update -y",
     "sudo apt-get upgrade -y",
     "sudo apt-get install nginx wireguard certbot python3-certbot-nginx -y",
     "sudo wget https://raw.githubusercontent.com/nginxinc/NGINX-Demos/master/nginx-hello/index.html --output-document /usr/share/nginx/html/index.html",
     "sudo wget https://raw.githubusercontent.com/nginxinc/NGINX-Demos/master/nginx-hello/hello.conf --output-document /etc/nginx/sites-enabled/default",
     "sudo mkdir -p /var/www/southwindroast/html",
     "sudo chown -R ubuntu:ubuntu /var/www/southwindroast/",
     "sudo chown -R ubuntu:ubuntu /var/www/",
     "sudo chown -R ubuntu:ubuntu /etc/nginx/",
     "sudo ln -s /etc/nginx/sites-available/southwindroast /etc/nginx/sites-enabled/",
     "sudo certbot --nginx -d southwindroast.com -d www.southwindroast.com --redirect",
     "sudo systemctl reload nginx",
   ]
   connection {
     type = "ssh"
     user = "ubuntu"
     private_key = file("nginx/will_terraform_key.pem")
     host = "${self.public_ip}"
   }
  }
  provisioner "file" {
    source = "nginx/southwindroast"
    destination = "/etc/nginx/sites-available/southwindroast"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("nginx/will_terraform_key.pem")
      host = "${self.public_ip}"
    }
  }
  provisioner "file" {
    source = "nginx/index.html"
    destination = "/var/www/southwindroast/html/index.html"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("nginx/will_terraform_key.pem")
      host = "${self.public_ip}"
    }
  }
  provisioner "file" {
    source = "nginx/nginx.conf"
    destination = "/etc/nginx/nginx.conf"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("nginx/will_terraform_key.pem")
      host = "${self.public_ip}"
    }
  }
}
/*resource "aws_instance" "auth_server" {
  ami           = "ami-00399ec92321828f5"
  associate_public_ip_address = var.associate_public_ip_address
  instance_type               = var.ec2_instance_type
  key_name                    = var.ec2_key_name
  monitoring                  = true
  vpc_security_group_ids      = var.vpc_security_group_ids
  user_data = templatefile("${path.module}/keycloakdata.tmpl", {})
  tags = {
    Name = "keycloak"
  }
}*/
