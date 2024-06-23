#!/bin/bash

yum update -y 
yum install -y vim wget net-tools.x86_64 bind-utils

systemctl stop firewalld.service
systemctl disable firewalld.service
