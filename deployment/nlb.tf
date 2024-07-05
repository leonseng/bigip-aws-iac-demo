resource "aws_security_group" "nlb" {
  name        = "${local.name_prefix}-nlb"
  vpc_id      = aws_vpc.main.id
  description = "NLB security group"

  ingress {
    description = "Access to BIG-IP virtual server"
    from_port   = 443
    to_port     = 443
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

resource "aws_lb" "nlb" {
  name                       = local.name_prefix
  internal                   = false
  load_balancer_type         = "network"
  enable_deletion_protection = false
  security_groups            = [aws_security_group.nlb.id]

  dynamic "subnet_mapping" {
    for_each = toset([for s in aws_subnet.external : s.id])
    content {
      subnet_id = subnet_mapping.value
    }
  }

  enable_cross_zone_load_balancing = true
}

# resource "aws_lb_target_group" "tg" {
#   name        = local.name_prefix
#   port        = 443
#   protocol    = "TCP"
#   vpc_id      = aws_vpc.main.id
#   target_type = "instance"

#   health_check {
#     interval            = 30
#     port                = "443"
#     protocol            = "TCP"
#     healthy_threshold   = 3
#     unhealthy_threshold = 3
#     timeout             = 10
#   }

#   tags = {
#     Name = local.name_prefix
#   }
# }

resource "aws_lb_target_group" "tg" {
  name        = local.name_prefix
  port        = 443
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    interval            = 30
    port                = "443"
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 10
  }

  tags = {
    Name = local.name_prefix
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group_attachment" "this" {
  count = var.aws_az_count

  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = module.bigip[count.index].private_addresses.public_private.private_ips[0][0]
  # target_id = module.bigip[count.index].private_addresses.external_private.private_ip[0]
  port = 443
}
