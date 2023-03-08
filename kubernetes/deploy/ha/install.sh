#!/bin/bash

log(){
 echo -e '\e[92m'$1'\e[0m'
}

log "start install kubernetes"

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



log "add hosts start"
master_list=(`echo $2 | tr ',' ' '`)

cat >> /etc/hosts << EOF
$8 api.k8s.local
EOF

for ((i=0; i<${#master_list[*]}; i++))
do
hostip=${master_list[$i]}
cat >> /etc/hosts << EOF
$hostip master-${hostip##*.}
EOF
done

node_list=(`echo $4 | tr ',' ' '` )
for ((i=0; i<${#node_list[*]}; i++))
do
hostip=${node_list[$i]}
cat >> /etc/hosts << EOF
$hostip node-${hostip##*.}
EOF
done
log "add hosts end"

log "kubernetes master start"
pass=$6
VIP=$8
JOIN=''
CERT=''
for ((i=0; i<${#master_list[*]}; i++ ))
do
  hostip=${master_list[$i]}
  log "当前安装节点$hostip"
  if [ $i -eq 0 ] ; then
    hostipctl set-hostname master-${hostip##*.}
    sh master.sh
    sh vip.sh $VIP

    export name=master-${hostip##*.}
    export ip=$hostip
    envsubst < kubeadm-temp.yaml > kubeadm.yaml

    kubeadm init --config kubeadm.yaml --upload-certs

    mkdir -p $HOME/.kube && sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && sudo chown $(id -u):$(id -g) $HOME/.kube/config

    log "kubernetes deploy flannel cni start"
    kubectl apply -f kube-flannel.yml
    log "kubernetes deploy flannel cni end"
    sleep 3
    JOIN=`kubeadm token create --print-join-command`
    CERT=`kubeadm init phase upload-certs --upload-certs | awk -F" " '{print $1}' |tail -n 1`
  else

    #TOKEN=`kubeadm token list | awk -F" " '{print $1}' |tail -n 1`
    #HASH=`openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -logform der 2>/dev/null | openssl dgst -sha256 -hex |awk -F '= ' '{print $2}'`
    expect_run_cmd $pass "ssh -l root $hostip \"hostipctl set-hostname master-${hostip##*.}\""
    expect_run_cmd $pass "scp /etc/hosts root@$hostip:/etc"
    expect_run_cmd $pass "scp -r kubeadm root@$hostip:/root"
    expect_run_cmd $pass "scp -r vip.sh root@$hostip:/root"
    expect_run_cmd $pass "scp -r master.sh root@$hostip:/root"
    expect_run_cmd $pass "ssh -l root $hostip \"sh master.sh\""
    expect_run_cmd $pass "ssh -l root $hostip \"$JOIN --control-plane --certificate-key $CERT\""
    expect_run_cmd $pass "ssh -l root $hostip \"mkdir -p /root/.kube && sudo cp -i /etc/kubernetes/admin.conf  /root/.kube/config && sudo chown \$(id -u):\$(id -g) /root/.kube/config\""
    expect_run_cmd $pass "ssh -l root $hostip \"sh vip.sh $VIP\""
  fi
done
log "kubernetes master end"

log "kubernetes node start"
for ((i=0; i<${#node_list[*]}; i++))
do
  hostip=${node_list[$i]}
  log "当前安装节点$hostip"
  expect_run_cmd $pass "ssh -l root $hostip \"hostipctl set-hostname node-${hostip##*.}\""
  expect_run_cmd $pass "scp /etc/hosts root@$hostip:/etc"
  expect_run_cmd $pass "scp -r node.sh root@$hostip:/root"
  expect_run_cmd $pass "scp -r /etc/kubernetes/admin.conf root@$hostip:/etc/kubernetes/"
  expect_run_cmd $pass "ssh -l root $hostip \"export KUBECONFIG=/etc/kubernetes/kubelet.conf\""
  expect_run_cmd $pass "ssh -l root $hostip \"source /etc/profile\""
  expect_run_cmd $pass "ssh -l root $hostip \"sh /root/node.sh\""
  expect_run_cmd $pass "ssh -l root $hostip \"$JOIN\""
done
log "kubernetes node end"