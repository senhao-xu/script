# kubernetes部署脚本

## 快速开始

### 在线部署

​		将本脚放入需要安装的Linux机器，执行`sh kubernetes-off-line.sh -master '[master-ip] -node [node-ip] -pass [node-password]'`

#### 单机部署案例

```sh
sh kubernetes-off-line.sh -master '10.1.52.11'
```

单机master 存在污点情况从而导致无法创建pod

解决方法：`kubectl taint nodes --all node-role.kubernetes.io/master-`

#### 多node部署

```sh
sh kubernetes-off-line.sh -master '10.1.52.11' -node '10.1.52.12,10.1.52.13' -pass 'root'
```

### 离线部署

​		同上
