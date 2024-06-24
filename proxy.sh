#!/bin/bash
ip=$1

if [ "$ip" = "" ]; then
    echo proxyAddr is null
    echo sh proxy.sh [10.0.0.5:7890]
    exit
fi

tee /etc/systemd/system/docker.service.d/proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=http://$ip"
Environment="HTTPS_PROXY=http://$ip"
Environment="NO_PROXY=localhost,127.0.0.1,.example.com"
EOF
