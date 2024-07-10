# BIG-IP Username
output "bigip_username" {
  value = module.bigip[0].f5_username
}

# BIG-IP Password
output "bigip_password" {
  value     = random_string.dynamic_password.result
  sensitive = true
}

output "bigip_urls" {
  value = [for b in module.bigip : {
    mgmt = "https://${b.mgmtPublicDNS}"
  }]
}

# VPC ID used for BIG-IP Deploy
output "vpc_id" {
  value = aws_vpc.main.id
}

output "nlb_public_dns" {
  value = aws_lb.nlb.dns_name
}
