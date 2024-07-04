#!/bin/bash

mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
sudo yum-config-manager --add-repo http://mirrors.tencentyun.com/repo/centos7_base.repo
sudo yum-config-manager --add-repo http://mirrors.tencentyun.com/repo/centos7_epel.repo

yum update -y 
yum install -y vim wget net-tools.x86_64 bind-utils

systemctl stop firewalld.service
systemctl disable firewalld.service
