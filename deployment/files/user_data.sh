#!/usr/bin/env bash
yum update -y
yum install -y docker
usermod -aG docker ec2-user
systemctl enable docker --now

docker run -d --name f5demo  --rm -p 80:80 f5devcentral/f5-demo-httpd:nginx
