#/bin/sh
read -p "$(echo -e "Please enter old ip: $none")" oldip
read -p "$(echo -e "Please enter new ip: $none")" newip

vi /etc/hosts -c '%s/$oldip/$newip/g | wq'
#backup old dir
cp -Rf /etc/kubernetes/ /etc/kubernetes-bak
#find old ip file
find /etc/kubernetes/ -type f | xargs grep $oldip
#update old ip by new ip
find /etc/kubernetes/ -type f | xargs sed -i "s/$oldip/$newip/"
#find updated file 
find /etc/kubernetes/ -type f | xargs grep $newip

cd /etc/kubernetes/pki
rm apiserver.crt apiserver.key

kubeadm init phase certs apiserver

rm etcd/peer.crt etcd/peer.key
kubeadm init phase certs etcd-peer

cd /etc/kubernetes
rm -f admin.conf kubelet.conf controller-manager.conf scheduler.conf
kubeadm init phase kubeconfig all
\cp /etc/kubernetes/admin.conf $HOME/.kube/config

systemctl restart docker
systemctl restart kubelet

kubectl -n kube-system edit cm kube-proxy -c '%s/$oldip/$newip/g'