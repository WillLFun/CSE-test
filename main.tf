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
# Create web server hosting Wireguard and NGINX
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
  #Imports client public key from makefile
  provisioner "file" {
    source = "wireguard/peer-publickey"
    destination = "/tmp/peer-publickey"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("nginx/$keypair.pem")
      host = "${self.public_ip}"
    }
  }
  # Server configurations
  provisioner "remote-exec" {
   inline = [
     # Prevents timing conflict between cloud-init and the package installations
     "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
     "sudo apt-get update -y",
     "sudo apt-get upgrade -y",
     "sudo apt-get install nginx wireguard certbot python3-certbot-nginx awscli -y",
     "sudo mkdir -p /var/www/southwindroast/html",
     "sudo chown -R ubuntu:ubuntu /var/www/southwindroast/",
     "sudo chmod -R 755 /var/www/southwindroast/",
     "sudo chown -R ubuntu:ubuntu /var/www/",
     "sudo chown -R ubuntu:ubuntu /etc/nginx/",
     "sudo ln -s /etc/nginx/sites-available/southwindroast /etc/nginx/sites-enabled/",
     "sudo mkdir /etc/wireguard/keys",
     "sudo chown -R ubuntu:ubuntu /etc/wireguard/",
     "sudo wg genkey | tee /etc/wireguard/keys/privatekey | wg pubkey > /etc/wireguard/keys/publickey",
     "sudo aws s3 cp /etc/wireguard/keys/publickey s3://wireguard-credentials/publickey",
   ]
   connection {
     type = "ssh"
     user = "ubuntu"
     private_key = file("nginx/$keypair.pem")
     host = "${self.public_ip}"
   }
  }
  # File provisioners to add config files
  provisioner "file" {
    source = "wireguard/wg0.conf"
    destination = "/etc/wireguard/wg0.conf"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("nginx/$keypair.pem")
      host = "${self.public_ip}"
    }
  }
  provisioner "file" {
    source = "wireguard/wire-config.sh"
    destination = "/etc/wireguard/wire-config.sh"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("nginx/$keypair.pem")
      host = "${self.public_ip}"
    }
  }
  provisioner "file" {
    source = "wireguard/config-temp.txt"
    destination = "/etc/wireguard/config-temp.txt"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("nginx/$keypair.pem")
      host = "${self.public_ip}"
    }
  }
  provisioner "file" {
    source = "nginx/southwindroast-temp"
    destination = "/etc/nginx/southwindroast-temp"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("nginx/$keypair.pem")
      host = "${self.public_ip}"
    }
  }
  # Server configurations dependent on file provisioners
  provisioner "remote-exec" {
   inline = [
     "sudo chmod ugo+x /etc/wireguard/wire-config.sh",
     "sudo chmod 777 /etc/wireguard/keys/privatekey",
     "sudo /etc/wireguard/wire-config.sh",
     "sudo systemctl restart nginx",
     "sudo wg-quick up wg0",
     "sysctl -w net.ipv4.ip_forward=1",
     # Remove --staging flag from cerbot when ready for production certs
     "sudo echo \"05 * * * * sudo certbot --staging --nginx -d app.southwindroast.com --non-interactive --agree-tos -m youremail@email.com\" > mycron",
     "sudo crontab mycron",
   ]
   connection {
     type = "ssh"
     user = "ubuntu"
     private_key = file("nginx/$keypair.pem")
     host = "${self.public_ip}"
   }
  }
  provisioner "file" {
    source = "nginx/index.html"
    destination = "/var/www/southwindroast/html/index.html"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("nginx/$keypair.pem")
      host = "${self.public_ip}"
    }
  }
  provisioner "file" {
    source = "nginx/nginx.conf"
    destination = "/etc/nginx/nginx.conf"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("nginx/$keypair.pem")
      host = "${self.public_ip}"
    }
  }
}
# Create A record for web server
resource "aws_route53_record" "southwind" {
  zone_id = "Z02132171N9ZS2TLQNMG3"
  name    = "app.southwindroast.com"
  type    = "A"
  ttl     = "60"
  records = [aws_instance.web_server.public_ip]
}
# Create Keycloak and Flask server
resource "aws_instance" "auth_server" {
  ami           = "ami-00399ec92321828f5"
  iam_instance_profile = "${aws_iam_instance_profile.test_profile.name}"
  associate_public_ip_address = var.associate_public_ip_address
  instance_type               = var.ec2_instance_type
  key_name                    = var.ec2_key_name
  monitoring                  = true
  vpc_security_group_ids      = var.vpc_security_group_ids
  tags = {
    Name = "keycloak"
  }
  provisioner "file" {
    source = "keycloak/keycloak-site"
    destination = "/tmp/keycloak-site"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("nginx/$keypair.pem")
      host = "${self.public_ip}"
    }
  }
  # Server configurations
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
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("keycloak/$keypair.pem")
    host = "${self.public_ip}"
  }
 }
 provisioner "file" {
   source = "keycloak/launch.sh"
   destination = "/opt/keycloak/bin/launch.sh"
   connection {
     type = "ssh"
     user = "ubuntu"
     private_key = file("keycloak/$keypair.pem")
     host = "${self.public_ip}"
   }
 }
 provisioner "file" {
   source = "keycloak/keycloak.service"
   destination = "/etc/systemd/system/keycloak.service"
   connection {
     type = "ssh"
     user = "ubuntu"
     private_key = file("keycloak/$keypair.pem")
     host = "${self.public_ip}"
   }
 }
 provisioner "file" {
   source = "keycloak/app.py"
   destination = "/home/ubuntu/flask_app/app.py"
   connection {
     type = "ssh"
     user = "ubuntu"
     private_key = file("keycloak/$keypair.pem")
     host = "${self.public_ip}"
   }
 }
 provisioner "file" {
   source = "keycloak/flask.service"
   destination = "/etc/systemd/system/flask.service"
   connection {
     type = "ssh"
     user = "ubuntu"
     private_key = file("keycloak/$keypair.pem")
     host = "${self.public_ip}"
   }
 }
 provisioner "remote-exec" {
  inline = [
   "sudo mv /tmp/keycloak-site /etc/nginx/sites-available/default",
   # Remove --staging flag from cerbot when ready for production certs
   "sudo echo \"05 * * * * sudo certbot --staging --nginx -d login.southwindroast.com --non-interactive --agree-tos -m youremail@email.com\" > /tmp/mycron",
   "sudo crontab /tmp/mycron",
   "sudo /opt/keycloak/bin/add-user-keycloak.sh -r master -u $user -p $password",
   "sudo systemctl daemon-reload",
   "sudo systemctl enable keycloak",
   "sudo systemctl enable flask",
   "sudo systemctl start keycloak",
   "sudo systemctl restart nginx",
   "cd ~/flask_app/",
   "nohup flask run &>/dev/null &",
   "sleep 1",
  ]
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("nginx/$keypair.pem")
    host = "${self.public_ip}"
  }
 }
}
# Create A record for auth server
resource "aws_route53_record" "roast" {
  zone_id = "Z02132171N9ZS2TLQNMG3"
  name    = "login.southwindroast.com"
  type    = "A"
  ttl     = "60"
  records = [aws_instance.auth_server.public_ip]
}
