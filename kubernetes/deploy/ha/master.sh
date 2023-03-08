#!/bin/bash
#设置颜色

log(){
 echo -e '\e[92m'$1'\e[0m'
}

log "stop firewalld start"
systemctl stop firewalld
systemctl disable firewalld
log "stop firewalld end"

log "stop selinux start"
setenforce 0
sed -i 's/enforcing/disabled/' /etc/selinux/config
log "stop selinux end"

log "stop swap start"
swapoff -a
sed -i 's/.*swap.*/#&/' /etc/fstab
log "stop swap end"

log "update bridge start"
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward=1
EOF
sysctl --system
log "update bridge end"

log "rpm recovery start"
yum install -y expect yum-utils
log "rpm recovery end"

log "docker install start"
if ! [ -x "$(command -v docker)" ]; then
yum install -y docker-ce-20.10.9-3.el7 docker-ce-cli-20.10.9-3.el7 containerd.io docker-compose-plugin
systemctl start docker
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://hub-mirror.c.163.com"],
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
systemctl enable docker
systemctl daemon-reload
systemctl restart docker
fi
log "docker install end"

log "kubeadm install start"
if ! [ -x "$(command -v kubectl)" ]; then
cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum install -y kubelet-1.22.5 kubeadm-1.22.5 kubectl-1.22.5 --disableexcludes=kubernetes
systemctl enable --now kubelet
fi
log "kubeadm install end"

mv /usr/bin/kubeadm /usr/bin/kubeadm_backup
cp kubeadm /usr/bin/kubeadm
chmod +x /usr/bin/kubeadm