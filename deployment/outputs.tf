# BIG-IP Username
output "bigip_username" {
  value = module.bigip[0].f5_username
}

# BIG-IP Password
output "bigip_password" {
  value     = random_string.dynamic_password.result
  sensitive = true
}

# output "bigip_mgmt_url" {
#   description = "Public URL for Management interface"
#   value       = "https://${module.bigip.mgmtPublicDNS}"
# }

# output "bigip_external_url" {
#   description = "Public URL for accessing BIG-IP virtual servers"
#   value       = "https://${data.aws_network_interface.bigip_external.association[0].public_dns_name}"
# }

# VPC ID used for BIG-IP Deploy
output "vpc_id" {
  value = aws_vpc.main.id
}
