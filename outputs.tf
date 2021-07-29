output "web_server_ip" {
  value = aws_instance.web_server.public_ip
}
output "auth_server_ip" {
  value = aws_instance.auth_server.public_ip
}
