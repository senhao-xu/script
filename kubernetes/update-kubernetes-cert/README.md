### 本脚本用于更新kubernetes证书

#### 使用

```bash
#授权
chmod 755 update-kubeadm-cert.sh
#执行
./update-kubeadm-cert.sh all 或者 bash update-kubeadm-cert.sh all
```

#### 查看

```bash
kubeadm alpha certs check-expiration
```

