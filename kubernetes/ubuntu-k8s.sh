#!/bin/bash

log(){
 echo '\e[92m'$1'\e[0m'
}

log "disable ufw"
ufw disable

log "disable swap"
swapoff -a; sed -i '/swap/d' /etc/fstab

log "open forward"
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward=1
EOF
sysctl -p /etc/sysctl.d/k8s.conf

log "add sources"
curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
cat << EOF > /etc/apt/sources.list.d/docker.list
deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable
EOF
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -
cat << EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial main
EOF
apt-get update

log "install docker"
apt-get install -y docker-ce=5:20.10.24~3-0~ubuntu-jammy docker-ce-cli=5:20.10.24~3-0~ubuntu-jammy
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://hub-mirror.c.163.com"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file":"1"
  },
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
systemctl daemon-reload && systemctl restart docker
systemctl enable docker

log "install kubectl"
apt-get -y install kubelet=1.22.5-00 kubeadm=1.22.5-00 kubectl=1.22.5-00
systemctl enable kubelet --now
log "init kubernetes"
kubeadm init --image-repository registry.aliyuncs.com/google_containers \
--kubernetes-version=v1.22.5 \
--pod-network-cidr=10.244.0.0/16 \
--service-cidr=10.96.0.0/12
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
