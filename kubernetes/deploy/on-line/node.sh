#!/bin/bash
#设置颜色

out(){
 echo -e "\033[42m$1\033[0m"
}

out "===============start install kubernetes"

out "===============stop firewalld start"
systemctl stop firewalld
systemctl disable firewalld
out "=================stop firewalld end"

out "==============stop selinux start"
setenforce 0
sed -i 's/enforcing/disabled/' /etc/selinux/config
out "=================stop selinux end"

out "==================stop swap start"
swapoff -a
sed -i 's/.*swap.*/#&/' /etc/fstab
out "===================stop swap end"

out "====================update bridge start"
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward=1
EOF
sysctl --system
out "===================update bridge end"

out "===================rpm install start"
yum install -y yum-utils expect
out "===================rpm install end"

out "==================docker install start"
if ! [ -x "$(command -v docker)" ]; then
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://cffh6cda.mirror.aliyuncs.com"],
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
systemctl enable docker
systemctl daemon-reload
systemctl restart docker
fi
out "==================docker install end"

out "======================kubeadm install start"
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
yum -y install kubelet-1.22.1 kubeadm-1.22.1 kubectl-1.22.1
systemctl enable --now kubelet
fi
out "===========================kubeadm install end"
