module "bigip" {
  depends_on = [
    module.vpc,
    aws_security_group.external,
    aws_security_group.mgmt,
    aws_security_group.internal,
    aws_secretsmanager_secret_version.this,
    aws_iam_instance_profile.this,
    aws_key_pair.this
  ]

  source                      = "F5Networks/bigip-module/aws"
  f5_ami_search_name          = var.f5_ami_search_name
  aws_secretmanager_auth      = true
  aws_secretmanager_secret_id = aws_secretsmanager_secret.this.id
  aws_iam_instance_profile    = aws_iam_instance_profile.this.id
  prefix                      = "${random_id.id.dec}-3nic-a"
  ec2_key_name                = aws_key_pair.this.key_name
  mgmt_subnet_ids             = [{ "subnet_id" = aws_subnet.mgmt.id, "public_ip" = true, "private_ip_primary" = "" }]
  mgmt_securitygroup_ids      = [aws_security_group.mgmt.id]
  internal_subnet_ids         = [{ "subnet_id" = module.vpc.private_subnets[0], "public_ip" = false, "private_ip_primary" = "" }]
  internal_securitygroup_ids  = [aws_security_group.internal.id]
  external_subnet_ids         = [{ "subnet_id" = module.vpc.public_subnets[0], "public_ip" = true, "private_ip_primary" = "", "private_ip_secondary" = "" }]
  external_securitygroup_ids  = [aws_security_group.external.id]
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  allowed_ips = length(var.allowed_ips) == 0 ? ["${chomp(data.http.myip.response_body)}/32"] : var.allowed_ips
}

#
# Create a security group for BIG-IP
#
resource "aws_security_group" "external" {
  name   = "${random_id.id.dec}-external"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "Access to BIG-IP virtual server"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.allowed_ips
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

#
# Create a security group for BIG-IP Management
#
resource "aws_security_group" "mgmt" {
  name   = "${random_id.id.dec}-mgmt"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "Access to BIG-IP TMUI"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.allowed_ips
  }

  ingress {
    description = "Access to BIG-IP via SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.allowed_ips
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

#
# Create a security group for BIG-IP
#
resource "aws_security_group" "internal" {
  name   = "${random_id.id.dec}-internal"
  vpc_id = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

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

resource "aws_secretsmanager_secret" "this" {
  name = "${random_id.id.dec}-secret"
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = random_string.dynamic_password.result
}

resource "aws_iam_policy" "this" {
  name   = "${random_id.id.dec}-iam-policy"
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
  name                = "${random_id.id.dec}-iam-role"
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
  name = "${random_id.id.dec}-iam-profile"
  role = aws_iam_role.this.name
}

resource "aws_key_pair" "this" {
  key_name   = "${random_id.id.dec}-keypair"
  public_key = var.ssh_public_key
}


data "aws_network_interface" "bigip_external" {
  depends_on = [
    module.bigip
  ]
  filter {
    name   = "group-id"
    values = [aws_security_group.external.id]
  }
}

resource "null_resource" "readiness_probe" {
  depends_on = [
    module.bigip
  ]

  count = var.enable_bigip_api_readiness_check ? 1 : 0

  provisioner "local-exec" {
    command = "${path.module}/files/readiness_probe.sh"
    environment = {
      BIGIP_USERNAME = module.bigip.f5_username
      BIGIP_PASSWORD = random_string.dynamic_password.result
      BIGIP_MGMT_URL = "https://${module.bigip.mgmtPublicDNS}"
    }
    interpreter = [
      "/usr/bin/env",
      "bash"
    ]
  }
}

resource "local_file" "configuration_tfvars" {
  depends_on = [
    module.bigip
  ]

  count = var.create_configuration_tfvars ? 1 : 0

  content = templatefile(
    "${path.module}/templates/configuration.tfvars.tpl",
    {
      bigip_hostname         = module.bigip.mgmtPublicDNS
      bigip_username         = module.bigip.f5_username
      bigip_password         = random_string.dynamic_password.result
      bigip_external_self_ip = "${module.bigip.private_addresses.public_private.private_ip[0]}/${split("/", local.public_subnet)[1]}"
      bigip_internal_self_ip = "${module.bigip.private_addresses.internal_private.private_ip[0]}/${split("/", local.private_subnet)[1]}"
      workload_ips           = jsonencode([for eni in data.aws_network_interface.f5_demo_httpd : eni.private_ip])
    }
  )
  filename = "${path.module}/../configuration/terraform.tfvars"
}
