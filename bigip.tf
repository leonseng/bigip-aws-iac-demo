#
# Create a security group for BIG-IP
#
module "external-network-security-group-public" {
  source = "terraform-aws-modules/security-group/aws"

  name        = format("%s-external-public-nsg-%s", var.prefix, random_id.id.hex)
  description = "Security group for BIG-IP "
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = var.AllowedIPs
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]

  # Allow ec2 instances outbound Internet connectivity
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

}

#
# Create a security group for BIG-IP Management
#
module "mgmt-network-security-group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = format("%s-mgmt-nsg-%s", var.prefix, random_id.id.hex)
  description = "Security group for BIG-IP Management"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = var.AllowedIPs
  ingress_rules       = ["https-443-tcp", "https-8443-tcp", "ssh-tcp"]

  # Allow ec2 instances outbound Internet connectivity
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

}

#
# Create a security group for BIG-IP
#
module "internal-network-security-group-public" {
  source = "terraform-aws-modules/security-group/aws"

  name        = format("%s-internal-nsg-%s", var.prefix, random_id.id.hex)
  description = "Security group for BIG-IP "
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = var.AllowedIPs
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]

  # Allow ec2 instances outbound Internet connectivity
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

}
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = format("%s-%s-%s", var.prefix, var.ec2_key_name, random_id.id.hex)
  public_key = tls_private_key.example.public_key_openssh
}

#
# Create BIG-IP
#
module "bigip-a" {
  source                     = "F5Networks/bigip-module/aws"
  count                      = var.instance_count
  f5_ami_search_name         = "F5 BIGIP-15* PAYG-Best 200Mbps*"
  prefix                     = format("%s-3nic", var.prefix)
  ec2_key_name               = aws_key_pair.generated_key.key_name
  mgmt_subnet_ids            = [{ "subnet_id" = aws_subnet.mgmt.id, "public_ip" = true, "private_ip_primary" = "" }]
  mgmt_securitygroup_ids     = [module.mgmt-network-security-group.security_group_id]
  external_securitygroup_ids = [module.external-network-security-group-public.security_group_id]
  internal_securitygroup_ids = [module.internal-network-security-group-public.security_group_id]
  external_subnet_ids        = [{ "subnet_id" = aws_subnet.external-public.id, "public_ip" = true, "private_ip_primary" = "", "private_ip_secondary" = "" }]
  internal_subnet_ids        = [{ "subnet_id" = aws_subnet.internal.id, "public_ip" = false, "private_ip_primary" = "" }]
}

module "bigip-b" {
  source                     = "F5Networks/bigip-module/aws"
  count                      = var.instance_count
  f5_ami_search_name         = "F5 BIGIP-15* PAYG-Best 200Mbps*"
  prefix                     = format("%s-3nic", var.prefix)
  ec2_key_name               = aws_key_pair.generated_key.key_name
  mgmt_subnet_ids            = [{ "subnet_id" = aws_subnet.mgmt.id, "public_ip" = true, "private_ip_primary" = "" }]
  mgmt_securitygroup_ids     = [module.mgmt-network-security-group.security_group_id]
  external_securitygroup_ids = [module.external-network-security-group-public.security_group_id]
  internal_securitygroup_ids = [module.internal-network-security-group-public.security_group_id]
  external_subnet_ids        = [{ "subnet_id" = aws_subnet.external-public.id, "public_ip" = true, "private_ip_primary" = "", "private_ip_secondary" = "" }]
  internal_subnet_ids        = [{ "subnet_id" = aws_subnet.internal.id, "public_ip" = false, "private_ip_primary" = "" }]
}
