#!/bin/bash
#设置颜色

out(){
 echo -e "\033[42m$1\033[0m"
}

read -p "$(echo -e "ip:")" ip
read -p "$(echo -e "path:")" path

mkdir -p $path

yum -y install nfs-utils rpcbind

cat >> /etc/exports << EOF
$path *(rw,sync,no_root_squash)
EOF

service nfs start && service rpcbind start

systemctl enable nfs && systemctl enable rpcbind

showmount -e $ip