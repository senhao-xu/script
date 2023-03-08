#!/bin/bash
mkdir -p /root/.kube && sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config && sudo chown $(id -u):$(id -g) /root/.kube/config
export VIP=$1
export INTERFACE=eth0
export KVVERSION=v0.3.9
alias kube-vip="docker run --network host --rm ghcr.io/kube-vip/kube-vip:$KVVERSION"
kube-vip manifest pod --interface $INTERFACE --vip $VIP --controlplane --services --arp --leaderElection | tee  /etc/kubernetes/manifests/kube-vip.yaml
sleep 3
sed -i "s/Always/IfNotPresent/g" `grep Always -rl /etc/kubernetes/manifests/kube-vip.yaml`