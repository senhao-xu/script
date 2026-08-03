#!/bin/bash
set -e

# 要求：root 执行
if [ "$(id -u)" -ne 0 ]; then
  echo "请用 root 执行：sudo bash $0"
  exit 1
fi

# 检测系统版本
. /etc/os-release
case "$ID:$VERSION_ID" in
  debian:12)
    DISTRO_NAME="Debian"
    CODENAME_FALLBACK="bullseye"
    ;;
  debian:13)
    DISTRO_NAME="Debian"
    CODENAME_FALLBACK="bookworm bullseye"
    ;;
  ubuntu:22.04)
    DISTRO_NAME="Ubuntu"
    CODENAME_FALLBACK="focal"
    ;;
  ubuntu:24.04)
    DISTRO_NAME="Ubuntu"
    CODENAME_FALLBACK="jammy focal"
    ;;
  ubuntu:26.04)
    DISTRO_NAME="Ubuntu"
    CODENAME_FALLBACK="noble jammy focal"
    ;;
  *)
    echo "不支持的系统：${ID:-unknown} ${VERSION_ID:-}，本脚本仅支持 Debian 12 / 13 和 Ubuntu 22.04 / 24.04 / 26.04"
    exit 1
    ;;
esac

CODENAME="$VERSION_CODENAME"
ARCH="$(dpkg --print-architecture)"

echo ">>> 系统检测：$DISTRO_NAME $VERSION_ID ($CODENAME)"
echo ">>> 架构：$ARCH"

echo ">>> 开始准备环境..."

echo ">>> 清理旧 Docker 源..."
rm -f /etc/apt/sources.list.d/docker.list

echo ">>> 安装依赖..."
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release

echo ">>> 添加 Docker GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://download.docker.com/linux/$ID/gpg" \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg


# ========= 函数定义 =========
# 写入指定 codename 的 Docker apt 源文件
write_docker_list() {
  cat >/etc/apt/sources.list.d/docker.list <<EOF
deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/$ID \
$1 stable
EOF
}

# 切换到指定 codename 源并刷新索引
switch_docker_source() {
  write_docker_list "$1"
  apt-get update
}

# 查询某大版本对应的完整版本号（基于当前 apt 缓存）
get_full_ver() {
  apt-cache madison docker-ce | awk -v m="$1" '$3 ~ m"\\." {print $3; exit}'
}


# ========= 写入当前源并查询版本 =========
echo ">>> 写入 Docker 源（$CODENAME）..."
switch_docker_source "$CODENAME"

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
USE_CN="$CODENAME"

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
  FULL_VER=$(get_full_ver "$MAJOR")

  # 当前 codename 查不到，遍历回退链
  if [ -z "$FULL_VER" ]; then
    echo ">>> 当前源（$CODENAME）中未找到 ${MAJOR}.x，尝试回退 codename..."
    for fb in $CODENAME_FALLBACK; do
      echo ">>> 尝试 codename：$fb"
      set +e
      switch_docker_source "$fb" >/dev/null 2>&1
      set -e
      FULL_VER=$(get_full_ver "$MAJOR")
      if [ -n "$FULL_VER" ]; then
        USE_CN="$fb"
        echo ">>> 在 $fb 源中匹配到版本：$FULL_VER"
        break
      fi
    done
  else
    echo ">>> 匹配到版本：$FULL_VER"
  fi

  if [ -z "$FULL_VER" ]; then
    echo "!!! 所有可用源中均未找到 ${MAJOR}.x 版本"
    exit 1
  fi
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


# ========= 收尾：锁定旧版本 + 恢复源 =========
if [ -n "$MAJOR" ]; then
  echo ">>> 锁定版本 ${MAJOR}.x，防止被 apt upgrade 升级..."
  apt-mark hold docker-ce docker-ce-cli >/dev/null
  echo "    已 hold：docker-ce、docker-ce-cli（升级前请先 apt-mark unhold）"

  if [ "$USE_CN" != "$CODENAME" ]; then
    echo ">>> 恢复 Docker 源为当前系统 codename（$CODENAME）..."
    write_docker_list "$CODENAME"
    apt-get update >/dev/null 2>&1 || true
  fi
fi

echo
echo "安装完成，当前 Docker 版本："
docker --version
