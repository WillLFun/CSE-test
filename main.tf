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

# Create S3 bucket
resource "aws_s3_bucket" "credentials" {
  bucket = "wireguard-credentials"
  acl    = "private"
}

resource "aws_instance" "web_server" {
  ami           = "ami-00399ec92321828f5"
  iam_instance_profile = "${aws_iam_instance_profile.test_profile.name}"
  associate_public_ip_address = var.associate_public_ip_address
  instance_type               = var.ec2_instance_type
  key_name                    = var.ec2_key_name
  monitoring                  = true
  vpc_security_group_ids      = var.vpc_security_group_ids
  tags = {
    Name = "wireguard-nginx"
  }
  #Pulls client public key from makefile
  provisioner "file" {
    source = "wireguard/peer-publickey"
    destination = "/tmp/peer-publickey"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("nginx/aws_key_pair.pem")
      host = "${self.public_ip}"
    }
  }
  provisioner "remote-exec" {
   inline = [
     # Prevents timing conflict between cloud-init and the package installations
     "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
     "sudo apt-get update -y",
     "sudo apt-get upgrade -y",
     "sudo apt-get install nginx wireguard certbot python3-certbot-nginx awscli -y",
     "sudo mkdir -p /var/www/southwindroast/html",
     "sudo chown -R ubuntu:ubuntu /var/www/southwindroast/",
     "sudo chown -R ubuntu:ubuntu /var/www/",
     "sudo chown -R ubuntu:ubuntu /etc/nginx/",
     "sudo ln -s /etc/nginx/sites-available/southwindroast /etc/nginx/sites-enabled/",
     "sudo mkdir /etc/wireguard/keys",
     "sudo chown -R ubuntu:ubuntu /etc/wireguard/",
     "sudo wg genkey | tee privatekey | wg pubkey > /etc/wireguard/keys/publickey",
     "sudo aws s3 cp /etc/wireguard/keys/publickey s3://wireguard-credentials/publickey",
     "sudo ip link add dev wg0 type wireguard",
     "sudo ip address add dev wg0 192.168.2.1/24",
     "wg set wg0 listen-port 51820 private-key /etc/wireguard/keys/privatekey peer \"$(cat /tmp/peer-publickey)\" allowed-ips 192.168.2.1/24",
     "sudo echo \"05 * * * * sudo certbot --staging --nginx -d southwindroast.com -d www.southwindroast.com --non-interactive --agree-tos -m williamloy23@gmail.com\" > mycron",
     "sudo crontab mycron",
   ]
   connection {
     type = "ssh"
     user = "ubuntu"
     private_key = file("nginx/aws_key_pair.pem")
     host = "${self.public_ip}"
   }
  }
  provisioner "file" {
    source = "nginx/southwindroast"
    destination = "/etc/nginx/sites-available/southwindroast"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("nginx/aws_key_pair.pem")
      host = "${self.public_ip}"
    }
  }
  provisioner "file" {
    source = "nginx/index.html"
    destination = "/var/www/southwindroast/html/index.html"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("nginx/aws_key_pair.pem")
      host = "${self.public_ip}"
    }
  }
  provisioner "file" {
    source = "nginx/nginx.conf"
    destination = "/etc/nginx/nginx.conf"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("nginx/aws_key_pair.pem")
      host = "${self.public_ip}"
    }
  }
}
resource "aws_route53_record" "southwind" {
  zone_id = "Z02132171N9ZS2TLQNMG3"
  name    = "app.southwindroast.com"
  type    = "A"
  ttl     = "60"
  records = [aws_instance.web_server.public_ip]
}

resource "aws_instance" "auth_server" {
  ami           = "ami-00399ec92321828f5"
  associate_public_ip_address = var.associate_public_ip_address
  instance_type               = var.ec2_instance_type
  key_name                    = var.ec2_key_name
  monitoring                  = true
  vpc_security_group_ids      = var.vpc_security_group_ids
  #user_data = templatefile("${path.module}/keycloakdata.tmpl", {})
  tags = {
    Name = "keycloak"
  }
  provisioner "file" {
    source = "keycloak/keycloak-site"
    destination = "/tmp/keycloak-site"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("nginx/aws_key_pair.pem")
      host = "${self.public_ip}"
    }
  }
  provisioner "remote-exec" {
   inline = [
    "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
    "sudo apt-get update",
    "sudo apt-get install default-jdk nginx certbot python3-certbot-nginx python3-pip awscli -y",
    "sudo pip install Flask",
    "cd /tmp",
    "wget https://github.com/keycloak/keycloak/releases/download/14.0.0/keycloak-14.0.0.tar.gz",
    "tar -xvzf keycloak-14.0.0.tar.gz",
    "sudo mv keycloak-14.0.0 /opt/keycloak",
    "sudo chown -R ubuntu:ubuntu /opt/keycloak",
    "chmod o+x /opt/keycloak/bin/",
    "mkdir /home/ubuntu/flask_app",
    "aws s3 cp s3://wireguard-credentials/publickey /home/ubuntu/flask_app/publickey",
    "cd /etc/",
    "sudo mkdir keycloak",
    "sudo cp /opt/keycloak/docs/contrib/scripts/systemd/wildfly.conf /etc/keycloak/keycloak.conf",
    "cp /opt/keycloak/docs/contrib/scripts/systemd/launch.sh /opt/keycloak/bin/launch.sh",
    "sudo cp /opt/keycloak/docs/contrib/scripts/systemd/wildfly.service /etc/systemd/system/keycloak.service",
    "sudo chown -R ubuntu:ubuntu /etc/systemd/system/",
   ]
   #remove staging from cerbot when finished
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("keycloak/aws_key_pair.pem")
    host = "${self.public_ip}"
  }
 }
 provisioner "file" {
   source = "keycloak/launch.sh"
   destination = "/opt/keycloak/bin/launch.sh"
   connection {
     type = "ssh"
     user = "ubuntu"
     private_key = file("keycloak/aws_key_pair.pem")
     host = "${self.public_ip}"
   }
 }
 provisioner "file" {
   source = "keycloak/keycloak.service"
   destination = "/etc/systemd/system/keycloak.service"
   connection {
     type = "ssh"
     user = "ubuntu"
     private_key = file("keycloak/aws_key_pair.pem")
     host = "${self.public_ip}"
   }
 }
 provisioner "file" {
   source = "keycloak/app.py"
   destination = "/home/ubuntu/flask_app/app.py"
   connection {
     type = "ssh"
     user = "ubuntu"
     private_key = file("keycloak/aws_key_pair.pem")
     host = "${self.public_ip}"
   }
 }
 provisioner "file" {
   source = "keycloak/flask.service"
   destination = "/etc/systemd/system/flask.service"
   connection {
     type = "ssh"
     user = "ubuntu"
     private_key = file("keycloak/aws_key_pair.pem")
     host = "${self.public_ip}"
   }
 }
 provisioner "remote-exec" {
  inline = [
   "sudo mv /tmp/keycloak-site /etc/nginx/sites-available/default",
   "sudo echo \"02 * * * * sudo certbot --staging --nginx -d login.southwindroast.com --non-interactive --agree-tos -m williamloy23@gmail.com\" > /tmp/mycron",
   "sudo crontab /tmp/mycron",
   "sudo /opt/keycloak/bin/add-user-keycloak.sh -r master -u williamloy -p !1Password!1",
   "sudo systemctl daemon-reload",
   "sudo systemctl enable keycloak",
   "sudo systemctl enable flask",
   "sudo systemctl start keycloak",
   "sudo systemctl start flask",
   "sudo systemctl restart nginx",
  ]
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("nginx/aws_key_pair.pem")
    host = "${self.public_ip}"
  }
 }
}
resource "aws_route53_record" "roast" {
  zone_id = "Z02132171N9ZS2TLQNMG3"
  name    = "login.southwindroast.com"
  type    = "A"
  ttl     = "60"
  records = [aws_instance.auth_server.public_ip]
}
