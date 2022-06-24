locals {
  workload_count = 2
}

resource "aws_security_group" "workload" {
  name   = "${random_id.id.dec}-workload"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "Access by BIG-IP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${module.bigip.private_addresses.internal_private.private_ip[0]}/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "workload" {
  count = local.workload_count
  depends_on = [
    module.vpc,
    aws_security_group.workload
  ]

  ami                    = var.workload_ami
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.workload.id]
  user_data              = file("${path.module}/files/user_data.sh")

  tags = {
    Name = "${random_id.id.dec}-workload-${count.index}"
  }
}

data "aws_network_interface" "f5_demo_httpd" {
  count = local.workload_count
  id    = aws_instance.workload[count.index].primary_network_interface_id
}
