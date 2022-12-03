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
#设置docker源
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
#安装docker
yum install -y docker-ce docker-ce-cli containerd.io
#配置加速器
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


out "===========================kubernetes master start"
master_list=(`echo $2 | tr ',' ' '` )
MASTER_INTERNAL_IP='';
for ((i=0; i<${#master_list[*]}; i++ ))
do
hostname=${master_list[$i]}
cat >> /etc/hosts << EOF
$hostname master$i
EOF
done

for ((i=0; i<${#master_list[*]}; i++ ))
do
MASTER_INTERNAL_IP=${master_list[$i]};
hostnamectl set-hostname master$i
kubeadm init --kubernetes-version=1.22.1 --apiserver-advertise-address=${master_list[$i]} --image-repository registry.aliyuncs.com/google_containers --service-cidr=10.96.0.0/12 --pod-network-cidr=10.244.0.0/16
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f kube-flannel.yml
done 
out "===========================kubernetes master end"

out "===========================kubernetes node start"
node_list=(`echo $4 | tr ',' ' '` )
for ((i=0; i<${#node_list[*]}; i++))
do
hostname=${node_list[$i]}
cat >> /etc/hosts << EOF
$hostname node$i
EOF
done
function expect_run_cmd (){
  pass=$1
  expect -c "set timeout -1;
        spawn $2
        expect {
            *yes/no* {send -- yes\r;exp_continue;}
            *assword:* {send -- $pass\r;exp_continue;}
            *id_rsa):* {send -- \r;exp_continue}
            *y/n)?* {send -- y\r;exp_continue}
            *passphrase* {send -- \r;exp_continue}
            eof        {exit 0;}
        }";
}
#从机密码必须统一
TOKEN=`kubeadm token list | awk -F" " '{print $1}' |tail -n 1`
HASH=`openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex |awk -F '= ' '{print $2}'`

for ((i=0; i<${#node_list[*]}; i++))
do
hostname=${node_list[$i]}
pass=$6
out "===========================当前安装节点$hostname$i"
expect_run_cmd $pass "ssh -l root $hostname \"hostnamectl set-hostname node$i\""
expect_run_cmd $pass "scp /etc/hosts root@$hostname:/etc"
expect_run_cmd $pass "scp -r node.sh root@$hostname:/root"
expect_run_cmd $pass "scp -r /etc/kubernetes/admin.conf root@$hostname:/etc/kubernetes/"
expect_run_cmd $pass "ssh -l root $hostname \"export KUBECONFIG=/etc/kubernetes/kubelet.conf\""
expect_run_cmd $pass "ssh -l root $hostname \"source /etc/profile\""
expect_run_cmd $pass "ssh -l root $hostname \"sh /root/node.sh\""
expect_run_cmd $pass "ssh -l root $hostname \"kubeadm join $MASTER_INTERNAL_IP:6443 --token $TOKEN --discovery-token-ca-cert-hash sha256:$HASH\""
done
out "===========================kubernetes node end"
