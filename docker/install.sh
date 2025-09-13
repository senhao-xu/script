!/bin/bash

curl -fsSL https://get.docker.com | bash -s docker && systemctl enable --now docker

tee /etc/docker/daemon.json <<-'EOF'
{
    "registry-mirrors": [
    ],
    "log-driver": "json-file",
    "log-opts": {
      "max-size": "100m",
      "max-file": "5"
    },
    "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
#重启docker
systemctl daemon-reload && systemctl restart docker
