#!/bin/bash
#判断docker是否已经被安装
if ! [ -x "$(command -v docker)" ]; then
#安装依赖包
yum install -y yum-utils
#设置docker源
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
#安装docker
yum install -y docker-ce docker-ce-cli containerd.io
#配置加速器
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://cffh6cda.mirror.aliyuncs.com"]
}
EOF
#设置docker开机自启
systemctl enable docker
systemctl daemon-reload
#重新启动docker
systemctl restart docker
#设置docker服务开机自启
systemctl enable docker
#验证docker已经安装成功
echo "Successfully installed docker-ce"
else
  echo "docker has been installed"
fi