resource "random_id" "id" {
  byte_length = 2
  prefix      = "${var.project_name}-"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  name_prefix = random_id.id.dec
  my_ip       = chomp(data.http.myip.response_body)
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.this.private_key_pem
  filename        = "${path.module}/.tmp/id_rsa"
  file_permission = "0400"
}

resource "aws_key_pair" "this" {
  key_name   = local.name_prefix
  public_key = tls_private_key.this.public_key_openssh
}
