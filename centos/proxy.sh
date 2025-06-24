#!/bin/bash

PROXY="http://10.2.12.32:10808"
PROFILE_FILE="/etc/profile.d/proxy.sh"

function enable_proxy() {
  echo "🔧 设置系统代理环境变量..."
  sudo tee "$PROFILE_FILE" > /dev/null <<EOF
export http_proxy=$PROXY
export https_proxy=$PROXY
export HTTP_PROXY=$PROXY
export HTTPS_PROXY=$PROXY
export no_proxy="localhost,127.0.0.1"
export NO_PROXY="localhost,127.0.0.1"
EOF
  sudo chmod +x "$PROFILE_FILE"
  echo "✅ 系统环境代理变量已设置"
  echo "⚠️ 请重新登录或执行 'source $PROFILE_FILE' 使环境变量生效"
}

function disable_proxy() {
  echo "🧹 移除系统代理环境变量..."
  if [ -f "$PROFILE_FILE" ]; then
    sudo rm -f "$PROFILE_FILE"
    echo "✅ 已删除 $PROFILE_FILE"
  else
    echo "⚠️ $PROFILE_FILE 不存在，无需删除"
  fi
  echo "✅ 系统代理已关闭"
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
