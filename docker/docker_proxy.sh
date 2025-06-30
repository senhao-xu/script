#!/bin/bash

PROXY="http://10.2.12.32:10808"
CONFIG_DIR="/etc/systemd/system/docker.service.d"
CONFIG_FILE="$CONFIG_DIR/http-proxy.conf"

function enable_proxy() {
  echo "🔧 配置 Docker daemon 使用代理..."
  sudo mkdir -p "$CONFIG_DIR"

  cat <<EOF | sudo tee "$CONFIG_FILE" > /dev/null
[Service]
Environment="HTTP_PROXY=$PROXY"
Environment="HTTPS_PROXY=$PROXY"
Environment="NO_PROXY=localhost,127.0.0.1"
EOF

  echo "✅ Docker daemon 代理配置完成"
  reload_and_restart
}

function disable_proxy() {
  echo "🧹 移除 Docker daemon 代理配置..."

  if [ -f "$CONFIG_FILE" ]; then
    sudo rm -f "$CONFIG_FILE"
    echo "✅ 已删除 $CONFIG_FILE"
  else
    echo "⚠️ 文件 $CONFIG_FILE 不存在，无需删除"
  fi

  reload_and_restart
}

function reload_and_restart() {
  echo "🔄 重载 systemd 并重启 Docker..."
  systemctl daemon-reload && systemctl restart docker
  echo "✅ 操作完成！"
}

function usage() {
  echo "Usage: $0 {enable|disable}"
  exit 1
}

if [ "$#" -ne 1 ]; then
  usage
fi

case "$1" in
  enable)
    enable_proxy
    ;;
  disable)
    disable_proxy
    ;;
  *)
    usage
    ;;
esac
