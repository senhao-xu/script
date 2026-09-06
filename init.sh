#!/usr/bin/env bash
#===============================================================================
# 服务器初始化脚本
# 适用系统: Debian 12 / Ubuntu (需要 root 权限)
# 内容: 基础工具、vim 鼠标模式、bash 别名、UFW 防火墙、fail2ban
# 用法: chmod +x init_server.sh && sudo ./init_server.sh
#===============================================================================
set -euo pipefail

#-------------------- 检查 root 权限 --------------------
if [[ $EUID -ne 0 ]]; then
    echo "错误: 请使用 root 运行本脚本 (sudo $0)" >&2
    exit 1
fi

echo "==> [1/5] 更新软件源并安装基础工具"
apt update
apt install -y curl wget vim

echo "==> [2/5] 关闭 vim 默认的鼠标模式 (修复右键无法复制粘贴)"
# 用通配符兼容不同版本的 vim 目录 (vim81/vim90/...)
for f in /usr/share/vim/vim*/defaults.vim; do
    if [ -f "$f" ]; then
        sed -i 's/^    set mouse=a/    set mouse-=a/' "$f"
    fi
done

echo "==> [3/5] 启用 ~/.bashrc 中被注释掉的 ls 相关别名"
sed -i '/^# export LS_OPTIONS=/s/^# //' ~/.bashrc
sed -i '/^# eval "\$(dircolors)"/s/^# //' ~/.bashrc
sed -i '/^# alias ls=/s/^# //' ~/.bashrc
sed -i '/^# alias ll=/s/^# //' ~/.bashrc
sed -i '/^# alias l=/s/^# //' ~/.bashrc
# 注意: 在脚本里 source 不会影响你当前的终端,
#       脚本跑完后请手动执行 source ~/.bashrc 或重新登录

echo "==> [4/5] 安装并配置 UFW 防火墙"
apt install -y ufw
ufw allow ssh
ufw allow 1123
ufw allow 80
ufw allow 443
# enable --now: 设置开机自启并立即启动
systemctl enable ufw --now

echo "==> [5/5] 安装并配置 fail2ban (SSH 防暴力破解)"
apt install -y fail2ban
tee /etc/fail2ban/jail.d/sshd.local > /dev/null <<'EOF'
[sshd]
enabled  = true
port     = ssh
filter   = sshd
# 通过 systemd 获取错误登录
backend  = systemd
# 1 次失败
maxretry = 1
# 在 60 秒(1 分钟)内
findtime = 60
# 封禁 3600 秒(1 小时)；可用 'bantime = -1' 永久封禁
bantime  = -1
# 白名单（本机、运维 IP）
ignoreip = 127.0.0.1/8

# ufw
action = ufw[name=sshd, port="ssh", protocol=tcp]
# iptables
# action = iptables-multiport[name=sshd, port="ssh", protocol=tcp]
EOF

systemctl enable --now fail2ban
systemctl restart fail2ban

echo "==> 初始化完成!"
echo "    - 别名生效:        source ~/.bashrc (或重新登录)"
echo "    - 防火墙状态:      ufw status"
echo "    - fail2ban 封禁列表: fail2ban-client status sshd"
