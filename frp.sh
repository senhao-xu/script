#!/bin/bash


check(){
  if  [ ! -e '/usr/bin/wget' ]; then
          echo " Installing Wget ..."
          yum -y install wget > /dev/null 2>&1
  fi
}

install_frps(){
  wget https://github.com/fatedier/frp/releases/download/v0.59.0/frp_0.59.0_linux_amd64.tar.gz
  mkdir -p /opt/frps/
  tar -zxvf frp_0.59.0_linux_amd64.tar.gz --strip-components=1 -C /opt/frps/

  tee /etc/systemd/system/frps.service <<EOF
[Unit]
# 服务名称，可自定义
Description = frps
After = network.target syslog.target
Wants = network.target

[Service]
Type = simple
# 启动frps的命令，需修改为您的frps的安装路径
ExecStart = /opt/frps/frps -c /opt/frps/frps.toml

[Install]
WantedBy = multi-user.target

EOF


  tee /opt/frps/frps.toml <<EOF
[common]
bind_port = 7000
vhost_http_port = 8080
vhost_https_port = 8081
dashboard_addr = 0.0.0.0
dashboard_port = 7500
dashboard_user = xusenhao
dashboard_pwd = xu20001123
token=xusenhao@1123
# frp日志配置
log_file = /var/log/frps.log
log_level = info
log_max_days = 3

EOF

systemctl enable frps
systemctl start frps
}


install_frpc(){
  wget https://github.com/fatedier/frp/releases/download/v0.59.0/frp_0.59.0_linux_amd64.tar.gz
  mkdir -p /opt/frps/
  tar -zxvf frp_0.59.0_linux_amd64.tar.gz --strip-components=1 -C /opt/frps/

  tee /etc/systemd/system/frpc.service <<EOF
[Unit]
# 服务名称，可自定义
Description = frpc
After = network.target syslog.target
Wants = network.target

[Service]
Type = simple
# 启动frps的命令，需修改为您的frps的安装路径
ExecStart = /opt/frps/frpc -c /opt/frps/frpc.toml

[Install]
WantedBy = multi-user.target

EOF


  tee /opt/frps/frpc.toml <<EOF
[common]
# 服务端公网IP
server_addr = [服务端公网IP]
# 客户端访问服务端的密码
token = abcdefg
# 客户端与服务端通信端口
server_port = 7000

[range:ssh]
# 指定TCP连接类型
type = tcp
# 客户端IP, 这里填本地IP就可以
local_ip = 127.0.0.1
# 当前设备开放的远程连接端口, 默认为22
local_port = 22
# 表示服务端的代理端口号
remote_port = 33022
# 是否加密
use_encryption = true
# 是否压缩
use_compression = false


EOF

systemctl enable frpc
systemctl start frpc
}