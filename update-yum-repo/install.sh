#!/bin/bash
out(){
 echo -e "\033[42m$1\033[0m"
}
out "===============update yum aliyun repo"
out "===============start backup repo"
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
out "===============end backup repo"
out "===============update yum repo"
mv CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
out "===============end yum repo"
out "===============update yum cache"
yum clean all
yum makecache
out "===============end yum cache"