variable "prefix" {
  description = "Prefix for resources created by this module"
  type        = string
  default     = "nginx-demo-app"
}

variable "associate_public_ip_address" {
  description = "Associate a public IP with the EC2 instance"
  type        = bool
  default     = true
}

variable "vpc_security_group_ids" {
  description = "List of AWS VPC Security Group IDs"
  type        = list
  default     = []
}

/*variable "vpc_subnet_ids" {
  description = "AWS VPC Subnet ID"
  type        = string
}*/

variable "ec2_key_name" {
  description = "AWS EC2 Key name for SSH access"
  type        = string
}

variable "ec2_instance_type" {
  description = "AWS EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ec2_instance_count" {
  description = "Number of instances to deploy"
  type        = number
  default     = 2
}
