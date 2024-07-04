#!/bin/bash

#https://mirrors.cloud.tencent.com/
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.cloud.tencent.com/repo/centos7_base.repo

yum update -y 
yum install -y vim wget net-tools.x86_64 bind-utils

systemctl stop firewalld.service
systemctl disable firewalld.service
