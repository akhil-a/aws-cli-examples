#!/bin/bash

echo "ClientAliveInterval 60" >> /etc/sshd_config
systemctl restart ssd.service

yum install httpd php git -y
sudo systemctl restart httpd.service php-fpm.service
sudo systemctl enable httpd.service php-fpm.service

git clone https://github.com/akhil-a/test-site.git
cp -r aws-elb-site/* /var/www/html/
chown -R apache:apache /var/www/html/*

