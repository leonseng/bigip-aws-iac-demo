variable "project_name" {
  description = "Prefix for resources created by this module"
  type        = string
  default     = "tf-aws-bigip"
}

variable "region" {
  default = "ap-southeast-2"
}

variable "aws_az_count" {
  type    = number
  default = 1
}

variable "aws_vpc_cidr" {
  description = "aws VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "allowed_ips" {
  description = "IP ranges allowed to access port 80 and 443 on BIG-IP. If none provided, only the IP address of the host executing `terraform apply` will be allowed"
  default     = []
}

variable "f5_ami_search_name" {
  # test the search string with the AWS CLI tool, e.g.
  #   aws ec2 describe-images --filters "Name=name,Values=F5 BIGIP-16* PAYG-Best*200Mbps*" | jq .Images[].Name
  description = "BIG-IP AMI name to search for"
  type        = string
  default     = "F5 BIGIP-17* PAYG-Best*25Mbps*"
}

variable "ssh_public_key" {
  description = "SSH public key to be added onto all EC2 instances"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDDNAVhes9z/HUfoiKDpyE2vD9ALtfMSVJ/mc1WkJjTeYTEUnVYZ/TjLiPXPmwhT5Jzp6S8kveeeBM77y6mlReOkefdDRmmuZL8MMPt3dn0lSI6GC11GndlxEBe47eKJ2B5pq36W8nveJH7Wek96YzQsJT9XqzKE9H38IWsaoy+mqbMjBEBdfE1eTCUbxtQinjJq2eVvinhsezzS3LlAgGk0tk5ZwX0UeYze4PA4znK7ppu9Epb8NYqYlRPYud7b1O5w1+7SKq1QGZRI5x9Qw+gXRRASGV1rRlTrSxUSWyMiXQMahr0QqAw+7r1jEJPS4/9QeEIBlLmWqBV2px9JI0PvseGNbX1XPB/WB4uw19aqF6Bbg51KGqsz4iRSjxLiHbIHeW+ttEbyMbAjpYFSNjOCgD2aL8kIBcjoQxS7azcs0RdWuIMoFRJYyvmQklMtQK9dClQQ4rHlR/G4wBevFayH7PthH8OIbwOaJ/lgk/yEMjMYcKetfzioA4rWhDS/vM="
}

variable "create_configuration_tfvars" {
  description = "Toggle to create terraform.tfvars in ../configuration/ for Configuration Terraform project"
  type        = bool
  default     = "true"
}

variable "tags" {
  description = "key:value tags to apply to resources built by the module"
  type        = map(any)
  default     = {}
}
