#!/bin/bash

log(){
 echo -e '\e[92m'$1'\e[0m'
}

version=1.24.4

log "init tools start"
yum install -y yum-utils
yum install -y yum-plugin-downloadonly
log "init tools end"

log "download expect and yum-utils start"
yum install -y --downloadonly --downloaddir=rpm/expect-rpm expect
log "download expect and yum-utils end"

log "download docker start"
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum install -y --downloadonly --downloaddir=rpm/docker-rpm docker-ce-20.10.9-3.el7 docker-ce-cli-20.10.9-3.el7 containerd.io docker-compose-plugin
log "download docker end"

log "download kubeadm end"
cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum install -y --downloadonly --downloaddir=rpm/kubeadm-rpm kubelet-$version kubeadm-$version kubectl-$version --disableexcludes=kubernetes
log "download kubeadm end"

tar -zcvf rpm.tar rpm

log "install docker start"
rpm -Uvh --force --nodeps rpm/docker-rpm/*.rpm
systemctl start docker
log "install docker end"

log "install kubeamd start"
rpm -Uvh --force --nodeps rpm/kubeadm-rpm/*.rpm
systemctl enable --now kubelet
log "install kubeamd end"

log "download kubeadm images start"
kubeadm config images pull --kubernetes-version $version --image-repository registry.aliyuncs.com/google_containers
docker save $(docker images | grep -v REPOSITORY | awk 'BEGIN{OFS=":";ORS=" "}{print $1,$2}') -o kube-$version-img.tar
log "download kubeadm images end"