#查看当前内核版本
uname -r
#更新源
yum -y update
#导入ELRepo仓库的公共密钥
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
#安装ELRepo仓库的yum源
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
#查询可用内核版本
yum --disablerepo="*" --enablerepo="elrepo-kernel" list available
#安装最新的稳定版本内核
yum -y --enablerepo=elrepo-kernel install kernel-lt
#查看系统上的所有可用内核
sudo awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg
#设置 grub2
grub2-set-default 0
#重启
reboot