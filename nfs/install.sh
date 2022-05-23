#!/bin/bash
#设置颜色

out(){
 echo -e "\033[42m$1\033[0m"
}

read -r -p '请输入ip(默认:'`ifconfig  eth0 | head -n2 | grep inet | awk '{print$2}'`'):' ip
[ -z "${ip}" ] && ip="`ifconfig  eth0 | head -n2 | grep inet | awk '{print$2}'`"
read -r -p '请输入挂载路径(默认:/data/nfs): ' path
[ -z "${path}" ] && path="/data/nfs"


mkdir -p $path

yum -y install nfs-utils rpcbind

cat >> /etc/exports << EOF
$path *(rw,sync,no_root_squash)
EOF

service nfs start && service rpcbind start

systemctl enable nfs && systemctl enable rpcbind

showmount -e $ip