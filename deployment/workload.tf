resource "aws_security_group" "workload" {
  name        = "${random_id.id.dec}-workload"
  vpc_id      = aws_vpc.main.id
  description = "Workload security group"

  ingress {
    description = "Access by BIG-IP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.internal_supernet]
  }

  egress {
    description = "Allow access to Internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  owners = ["137112412989"] # Amazon's AWS Account ID
}

resource "aws_instance" "workload" {
  count = var.aws_az_count
  depends_on = [
    aws_vpc.main,
    aws_security_group.workload,
    aws_route_table_association.internal
  ]

  ami                         = data.aws_ami.amazon_linux_2023.id
  key_name                    = aws_key_pair.this.key_name
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.internal[count.index].id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.workload.id]
  user_data                   = file("${path.module}/files/user_data.sh")

  root_block_device {
    encrypted = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    for k, v in merge(
      {
        Name = "${random_id.id.dec}-workload-${count.index}"
      },
      var.tags
    ) : k => v
  }
}

data "aws_network_interface" "f5_demo_httpd" {
  count = var.aws_az_count
  id    = aws_instance.workload[count.index].primary_network_interface_id
}
