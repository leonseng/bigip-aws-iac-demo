#
# Ran into a bug when plain password https://github.com/F5Networks/terraform-aws-bigip-module/issues/17
# So using AWS Secrets Manager to provide password instead.
#
resource "random_string" "dynamic_password" {
  length      = 16
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  special     = false
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "this" {
  name = local.name_prefix
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = random_string.dynamic_password.result
}

resource "aws_iam_policy" "this" {
  name   = local.name_prefix
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": ["${aws_secretsmanager_secret.this.arn}"]
        },
        {
            "Effect": "Allow",
            "Action": "secretsmanager:ListSecrets",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "this" {
  name                = local.name_prefix
  path                = "/"
  managed_policy_arns = [aws_iam_policy.this.arn]
  assume_role_policy  = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "this" {
  name = local.name_prefix
  role = aws_iam_role.this.name
}

#
# Create a security group for BIG-IP
#
resource "aws_security_group" "external" {
  name        = "${local.name_prefix}-external"
  vpc_id      = aws_vpc.main.id
  description = "BIG-IP client-side security group"

  ingress {
    description     = "Access to BIG-IP virtual server"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["${local.my_ip}/32"]
    security_groups = [aws_security_group.nlb.id]
  }

  egress {
    description = "Allow access to Internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#
# Create a security group for BIG-IP Management
#
resource "aws_security_group" "mgmt" {
  name        = "${local.name_prefix}-mgmt"
  vpc_id      = aws_vpc.main.id
  description = "BIG-IP management security group"

  ingress {
    description = "Access to BIG-IP TMUI"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${local.my_ip}/32"]
  }

  ingress {
    description = "Access to BIG-IP via SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${local.my_ip}/32"]
  }

  egress {
    description = "Allow access to Internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#
# Create a security group for BIG-IP
#
resource "aws_security_group" "internal" {
  name        = "${local.name_prefix}-internal"
  vpc_id      = aws_vpc.main.id
  description = "BIG-IP server-side security group"

  egress {
    description = "Allow access to Internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#tfsec:ignore:aws-ec2-enable-at-rest-encryption tfsec:ignore:aws-ec2-enforce-http-token-imds
module "bigip" {
  depends_on = [
    aws_vpc.main,
    aws_security_group.external,
    aws_security_group.mgmt,
    aws_security_group.internal,
    aws_secretsmanager_secret_version.this,
    aws_iam_instance_profile.this,
    aws_key_pair.this
  ]

  count = var.aws_az_count

  source                      = "F5Networks/bigip-module/aws"
  f5_ami_search_name          = var.f5_ami_search_name
  aws_secretmanager_auth      = true
  aws_secretmanager_secret_id = aws_secretsmanager_secret.this.id
  aws_iam_instance_profile    = aws_iam_instance_profile.this.id
  prefix                      = local.name_prefix
  ec2_key_name                = aws_key_pair.this.key_name
  mgmt_subnet_ids             = [{ "subnet_id" = aws_subnet.mgmt[count.index].id, "public_ip" = true, "private_ip_primary" = "" }]
  mgmt_securitygroup_ids      = [aws_security_group.mgmt.id]
  internal_subnet_ids         = [{ "subnet_id" = aws_subnet.internal[count.index].id, "public_ip" = false, "private_ip_primary" = "" }]
  internal_securitygroup_ids  = [aws_security_group.internal.id]
  external_subnet_ids         = [{ "subnet_id" = aws_subnet.external[count.index].id, "public_ip" = true, "private_ip_primary" = "", "private_ip_secondary" = "" }]
  external_securitygroup_ids  = [aws_security_group.external.id]
  tags = {
    for k, v in merge(
      {
        Name = "${local.name_prefix}-bigip-${count.index}"
      },
      var.tags
    ) : k => v
  }
}

# data "aws_network_interface" "bigip_external" {
#   depends_on = [
#     module.bigip
#   ]
#   filter {
#     name   = "group-id"
#     values = [aws_security_group.external.id]
#   }
# }

resource "null_resource" "readiness_probe" {
  depends_on = [
    module.bigip
  ]

  count = var.aws_az_count

  provisioner "local-exec" {
    command = "${path.module}/files/readiness_probe.sh"
    environment = {
      BIGIP_USERNAME = module.bigip[count.index].f5_username
      BIGIP_PASSWORD = random_string.dynamic_password.result
      BIGIP_MGMT_URL = "https://${module.bigip[count.index].mgmtPublicDNS}"
    }
    interpreter = [
      "/usr/bin/env",
      "bash"
    ]
  }
}

resource "local_file" "configuration_tfvars" {
  depends_on = [
    module.bigip,
    data.aws_network_interface.f5_demo_httpd
  ]

  count = var.create_configuration_tfvars ? var.aws_az_count : 0

  content = templatefile(
    "${path.module}/templates/configuration.tfvars.tpl",
    {
      bigip_address                = module.bigip[count.index].mgmtPublicIP
      bigip_instance_id            = module.bigip[count.index].bigip_instance_ids
      bigip_username               = module.bigip[count.index].f5_username
      bigip_password               = random_string.dynamic_password.result
      bigip_external_self_ip       = "${module.bigip[count.index].private_addresses.public_private.private_ip[0]}/${split("/", aws_subnet.external[count.index].cidr_block)[1]}"
      bigip_external_route_network = local.external_supernet
      bigip_external_route_gw      = cidrhost(aws_subnet.external[count.index].cidr_block, 1)
      bigip_internal_self_ip       = "${module.bigip[count.index].private_addresses.internal_private.private_ip[0]}/${split("/", aws_subnet.internal[count.index].cidr_block)[1]}"
      bigip_internal_route_network = local.internal_supernet
      bigip_internal_route_gw      = cidrhost(aws_subnet.internal[count.index].cidr_block, 1)
      workload_ips                 = jsonencode([for eni in data.aws_network_interface.f5_demo_httpd : eni.private_ip])
    }
  )
  filename = "${path.module}/../configuration/${module.bigip[count.index].bigip_instance_ids}.tfvars"
}
