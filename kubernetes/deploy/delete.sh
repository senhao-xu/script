#!/bin/bash
out(){
 echo -e "\033[42m$1\033[0m"
}
out "===============start uninstall kubernetes"
kubeadm reset -f
modprobe -r ipip
lsmod
rm -rf ~/.kube/
rm -rf /etc/kubernetes/
rm -rf /var/lib/kubelet/
rm -rf /etc/sysctl.d/k8s.conf
rm -rf /etc/systemd/system/kubelet.service.d
rm -rf /etc/systemd/system/kubelet.service
rm -rf /usr/bin/kube*
rm -rf /etc/cni
rm -rf /opt/cni
rm -rf /var/lib/etcd
rm -rf /var/etcd
yum clean all
yum remove -y kubelet-1.22.1 kubeadm-1.22.1 kubectl-1.22.1
out "===============end uninstall kubernetes"

out "===============start uninstall docker"
systemctl stop docker
yum remove -y docker-ce docker-ce-cli containerd.io
rm -rf /var/lib/docker
rm -rf /var/lib/containerd