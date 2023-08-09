data "aws_ami" "f5_ami" {
  most_recent = true
  // owners      = ["679593333241"]
  owners = ["aws-marketplace"]

  filter {
    name   = "description"
    values = [var.ami_description]
  }
}

output "ami" {
  value = data.aws_ami.f5_ami.id
}
