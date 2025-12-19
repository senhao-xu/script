#!/bin/bash
set -e

# 要求：root 执行
if [ "$(id -u)" -ne 0 ]; then
  echo "请用 root 执行：sudo bash $0"
  exit 1
fi

echo
echo "================ 请选择 Docker 版本 ================"
echo "  1) latest（最新稳定版，不锁版本）"
echo "  2) 最新的 28.x 版本"
echo "  3) 最新的 27.x 版本"
echo "  4) 最新的 26.x 版本"
echo "===================================================="
read -rp "请输入选项 [1-4]: " CHOICE
echo

MAJOR=""
FULL_VER=""

case "$CHOICE" in
  1)
    echo ">>> 选择：latest（最新稳定版）"
    ;;
  2)
    MAJOR="28"
    echo ">>> 选择：$MAJOR.x 最新版本"
    ;;
  3)
    MAJOR="27"
    echo ">>> 选择：$MAJOR.x 最新版本"
    ;;
  4)
    MAJOR="26"
    echo ">>> 选择：$MAJOR.x 最新版本"
    ;;
  *)
    echo "无效选项：$CHOICE"
    exit 1
    ;;
esac


echo ">>> 开始准备环境..."

echo ">>> 清理旧 Docker 源..."
rm -f /etc/apt/sources.list.d/docker.list

echo ">>> 安装依赖..."
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release

echo ">>> 添加 Docker GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
ARCH="$(dpkg --print-architecture)"

echo ">>> 系统：Debian $CODENAME, 架构：$ARCH"

echo ">>> 写入 Docker 源..."
cat >/etc/apt/sources.list.d/docker.list <<EOF
deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian \
$CODENAME stable
EOF

echo ">>> 更新软件源..."
apt-get update


# ========= 匹配版本（如果选择了大版本） ==========
if [ -n "$MAJOR" ]; then
  echo ">>> 正在查询 $MAJOR.x 最新版本号..."
  FULL_VER=$(apt-cache madison docker-ce | awk -v m="$MAJOR" '$3 ~ m"\\." {print $3; exit}')

  if [ -z "$FULL_VER" ]; then
    echo "!!! 无法找到 $MAJOR.x 版本，请检查仓库是否支持"
    echo "可用版本如下："
    apt-cache madison docker-ce
    exit 1
  fi

  echo ">>> 匹配到最新版本：$FULL_VER"
fi

echo ">>> 添加 Docker配置..."
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
    "registry-mirrors": [],
    "log-driver": "json-file",
    "log-opts": {
      "max-size": "100m",
      "max-file": "5"
    },
    "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF


# ========= 安装 Docker ==========
echo ">>> 开始安装 Docker..."

if [ -n "$FULL_VER" ]; then
  apt-get install -y \
    docker-ce="$FULL_VER" \
    docker-ce-cli="$FULL_VER" \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
else
  apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
fi

echo ">>> 启动 Docker 并设置开机自启..."
systemctl enable --now docker

echo
echo "🎉 安装完成，当前 Docker 版本："
docker --version

rm -f /etc/apt/sources.list.d/docker.list
