#!/bin/bash
set -e

# 要求：root 执行
if [ "$(id -u)" -ne 0 ]; then
  echo "请用 root 执行：sudo bash $0"
  exit 1
fi

# 检测系统版本
. /etc/os-release
if [ "$ID" != "debian" ] || { [ "$VERSION_ID" != "12" ] && [ "$VERSION_ID" != "13" ]; }; then
  echo "不支持的系统：${ID:-unknown} ${VERSION_ID:-}，本脚本仅支持 Debian 12 / Debian 13"
  exit 1
fi
echo ">>> 系统检测：Debian $VERSION_ID ($VERSION_CODENAME)"

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

CODENAME="$VERSION_CODENAME"
ARCH="$(dpkg --print-architecture)"

echo ">>> 架构：$ARCH"

echo ">>> 写入 Docker 源..."
cat >/etc/apt/sources.list.d/docker.list <<EOF
deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian \
$CODENAME stable
EOF

echo ">>> 更新软件源..."
apt-get update


# ========= 动态获取可用版本 ==========
echo ">>> 正在查询可用 Docker 版本..."
MAJORS=$(apt-cache madison docker-ce | awk '{print $3}' | sed 's/^[0-9]*://' | cut -d. -f1 | sort -rnu)

if [ -z "$MAJORS" ]; then
  echo "!!! 无法获取 Docker 版本列表，请检查网络和仓库配置"
  exit 1
fi

LATEST_MAJOR=$(echo "$MAJORS" | head -1)

echo
echo "================ 请选择 Docker 版本 ================"
IDX=1
for m in $MAJORS; do
  if [ "$m" = "$LATEST_MAJOR" ]; then
    echo "  ${IDX}) ${m}.x（latest）"
  else
    echo "  ${IDX}) ${m}.x"
  fi
  IDX=$((IDX + 1))
done
MAX_OPT=$((IDX - 1))
echo "===================================================="
read -rp "请输入选项 [1-$MAX_OPT]: " CHOICE
echo

MAJOR=""
FULL_VER=""

if [ "$CHOICE" -ge 1 ] 2>/dev/null && [ "$CHOICE" -le "$MAX_OPT" ] 2>/dev/null; then
  MAJOR=$(echo "$MAJORS" | sed -n "${CHOICE}p")
  if [ "$MAJOR" = "$LATEST_MAJOR" ]; then
    echo ">>> 选择：${MAJOR}.x（最新稳定版，不锁版本）"
    MAJOR=""
  else
    echo ">>> 选择：${MAJOR}.x"
  fi
else
  echo "无效选项：$CHOICE"
  exit 1
fi


# ========= 匹配版本（如果选择了大版本） ==========
if [ -n "$MAJOR" ]; then
  FULL_VER=$(apt-cache madison docker-ce | awk -v m="$MAJOR" '$3 ~ m"\\." {print $3; exit}')

  if [ -z "$FULL_VER" ]; then
    echo "!!! 无法找到 $MAJOR.x 版本"
    exit 1
  fi

  echo ">>> 匹配到版本：$FULL_VER"
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
    docker-compose-plugin \
    docker-model-plugin
else
  apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin \
    docker-model-plugin
fi

echo ">>> 启动 Docker 并设置开机自启..."
systemctl enable --now docker

echo
echo "安装完成，当前 Docker 版本："
docker --version
