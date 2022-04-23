#!/bin/bash
#设置颜色

out(){
 echo -e "\033[42m$1\033[0m"
}
out "check gcc status"
if ! [ -x "$(command -v gcc)" ]; then
out "install gcc start"
yum install -y gcc
out "install gcc end"
fi
out "check gcc ok"

out "install redis start"
wget https://download.redis.io/releases/redis-6.2.6.tar.gz
tar -zxvf redis-6.2.6.tar.gz
make -C redis-6.2.6
out "install redis end"

make -C redis-6.2.6 install PREFIX=/usr/local/redis

tee /etc/systemd/system/redis.service <<-'EOF'
[Unit]
Description=redis-server
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/redis/bin/redis-server /usr/local/redis/bin/redis.conf
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

cp redis.conf /usr/local/redis/bin/
#开机自启
systemctl daemon-reload
systemctl start redis.service
systemctl enable redis.service

out "start open firewall"
firewall-cmd --zone=public --add-port=6379/tcp --permanent
firewall-cmd --reload
out "end open firewall"