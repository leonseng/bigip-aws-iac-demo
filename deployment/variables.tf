variable "prefix" {
  description = "Prefix for resources created by this module"
  type        = string
  default     = "tf-aws-bigip"
}

variable "region" {
  default = "ap-southeast-2"
}

variable "vpc_cidr" {
  description = "aws VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "allowed_ips" {
  description = "IP ranges allowed to access port 80 and 443 on BIG-IP. If none provided, only the IP address of the host executing `terraform apply` will be allowed"
  default     = []
}

variable "f5_ami_search_name" {
  description = "BIG-IP AMI name to search for"
  type        = string
  default     = "F5 BIGIP-16* PAYG-Best 200Mbps*"
}

variable "ssh_public_key" {
  description = "SSH public key to be added onto all EC2 instances"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDDNAVhes9z/HUfoiKDpyE2vD9ALtfMSVJ/mc1WkJjTeYTEUnVYZ/TjLiPXPmwhT5Jzp6S8kveeeBM77y6mlReOkefdDRmmuZL8MMPt3dn0lSI6GC11GndlxEBe47eKJ2B5pq36W8nveJH7Wek96YzQsJT9XqzKE9H38IWsaoy+mqbMjBEBdfE1eTCUbxtQinjJq2eVvinhsezzS3LlAgGk0tk5ZwX0UeYze4PA4znK7ppu9Epb8NYqYlRPYud7b1O5w1+7SKq1QGZRI5x9Qw+gXRRASGV1rRlTrSxUSWyMiXQMahr0QqAw+7r1jEJPS4/9QeEIBlLmWqBV2px9JI0PvseGNbX1XPB/WB4uw19aqF6Bbg51KGqsz4iRSjxLiHbIHeW+ttEbyMbAjpYFSNjOCgD2aL8kIBcjoQxS7azcs0RdWuIMoFRJYyvmQklMtQK9dClQQ4rHlR/G4wBevFayH7PthH8OIbwOaJ/lgk/yEMjMYcKetfzioA4rWhDS/vM="
}

variable "workload_ami" {
  description = "AMI ID for workload EC2 to be used as pool members"
  type        = string
  default     = "ami-0c635ee4f691a2310" # ap-southeast-2 Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
}

variable "enable_bigip_api_readiness_check" {
  description = "Toggle to wait for BIG-IP REST API to be ready before completing deployment. Useful if immediately running DO and AS3 configuration immediately after."
  type        = bool
  default     = "true"
}

variable "create_configuration_tfvars" {
  description = "Toggle to create terraform.tfvars in ../configuration/ for Configuration Terraform project"
  type        = bool
  default     = "true"
}
