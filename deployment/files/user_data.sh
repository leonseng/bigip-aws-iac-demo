#!/usr/bin/env bash
yum update -y
amazon-linux-extras install docker
service docker start
usermod -aG docker ec2-user
systemctl enable docker

docker run -d --name f5demo  --rm -p 80:80 f5devcentral/f5-demo-httpd:nginx
