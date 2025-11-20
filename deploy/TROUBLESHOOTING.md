# Dimensio 部署故障排除指南

## 🔥 Docker 镜像拉取超时问题

### 问题症状

```
ERROR [backend internal] load metadata for docker.io/library/python:3.9-slim
dial tcp 198.44.185.131:443: i/o timeout
```

### 原因

在国内服务器访问 Docker Hub 会非常慢或超时。

### 解决方案 1：使用快速修复脚本（推荐）

```bash
cd /root/dimensio/deploy
sudo bash fix-docker-registry.sh
```

脚本会自动：
- 配置多个国内镜像源
- 重启 Docker 服务
- 验证配置

### 解决方案 2：手动配置镜像加速器

```bash
# 1. 创建或编辑 Docker 配置文件
sudo mkdir -p /etc/docker
sudo vim /etc/docker/daemon.json

# 2. 添加以下内容
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com",
    "https://docker.m.daocloud.io"
  ]
}

# 3. 重启 Docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# 4. 验证配置
docker info | grep -A 10 "Registry Mirrors"
```

### 解决方案 3：重新运行部署脚本

更新后的 `deploy.sh` 已经集成了自动配置镜像加速器功能：

```bash
cd /root/dimensio/deploy
sudo bash deploy.sh
```

### 验证镜像加速器是否生效

```bash
# 查看 Docker 配置
docker info | grep -A 10 "Registry Mirrors"

# 测试拉取镜像
docker pull python:3.9-slim
```

---

## 🔧 其他常见问题

### 1. 端口 80 被占用

**症状：**
```
Error starting userland proxy: listen tcp 0.0.0.0:80: bind: address already in use
```

**解决方案：**
```bash
# 查看占用 80 端口的进程
sudo lsof -i :80

# 如果是系统 Nginx
sudo systemctl stop nginx
sudo systemctl disable nginx

# 如果是 Apache
sudo systemctl stop apache2
sudo systemctl disable apache2

# 重新启动服务
cd /root/dimensio/deploy/docker
docker compose up -d
```

### 2. Docker 服务未启动

**症状：**
```
Cannot connect to the Docker daemon
```

**解决方案：**
```bash
# 启动 Docker
sudo systemctl start docker

# 设置开机自启
sudo systemctl enable docker

# 检查状态
sudo systemctl status docker
```

### 3. 磁盘空间不足

**症状：**
```
no space left on device
```

**解决方案：**
```bash
# 查看磁盘使用
df -h

# 清理 Docker 资源
docker system prune -a --volumes

# 清理项目日志
cd /root/dimensio
rm -rf logs/*
rm -rf result/*

# 查看最大的目录
du -h --max-depth=1 / | sort -hr | head -20
```

### 4. 权限问题

**症状：**
```
Permission denied
```

**解决方案：**
```bash
# 确保使用 root 权限
sudo -i

# 设置目录权限
cd /root/dimensio
chmod 755 data result logs

# 设置脚本执行权限
chmod +x deploy/deploy.sh
chmod +x deploy/manage.sh
chmod +x run_compression.sh
```

### 5. 容器启动后立即退出

**症状：**
```
Status: Exited (1)
```

**解决方案：**
```bash
# 查看容器日志
cd /root/dimensio/deploy/docker
docker compose logs backend
docker compose logs frontend
docker compose logs nginx

# 重新构建容器
docker compose down
docker compose up -d --build --force-recreate

# 查看详细错误
docker compose up
```

### 6. 前端无法连接后端

**症状：**
前端页面能访问，但 API 请求失败

**解决方案：**
```bash
# 检查网络连通性
docker compose exec frontend ping backend

# 检查 Nginx 配置
docker compose exec nginx cat /etc/nginx/conf.d/default.conf
docker compose exec nginx nginx -t

# 重启 Nginx
docker compose restart nginx

# 查看 Nginx 日志
docker compose logs nginx
```

### 7. Python 依赖安装失败

**症状：**
```
ERROR: Could not find a version that satisfies the requirement
```

**解决方案：**

编辑 `deploy/docker/Dockerfile.backend`，在 pip install 前添加：

```dockerfile
# 配置 pip 使用国内镜像
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
```

然后重新构建：
```bash
cd /root/dimensio/deploy/docker
docker compose build --no-cache backend
docker compose up -d
```

### 8. 防火墙阻止访问

**症状：**
从外部无法访问服务器 80 端口

**解决方案：**
```bash
# 检查防火墙状态
sudo ufw status

# 允许 80 端口
sudo ufw allow 80/tcp

# 如果使用阿里云/腾讯云等云服务器
# 还需要在控制台的安全组中开放 80 端口
```

### 9. npm 安装失败

**症状：**
```
npm ERR! network timeout
```

**解决方案：**

编辑 `deploy/docker/Dockerfile.frontend`，在 npm install 前添加：

```dockerfile
# 配置 npm 使用国内镜像
RUN npm config set registry https://registry.npmmirror.com
```

然后重新构建：
```bash
cd /root/dimensio/deploy/docker
docker compose build --no-cache frontend
docker compose up -d
```

### 10. 数据目录权限问题

**症状：**
```
Permission denied: '/app/data'
```

**解决方案：**
```bash
cd /root/dimensio
sudo chown -R 1000:1000 data result logs
sudo chmod -R 755 data result logs
```

---

## 📋 诊断命令清单

### 检查 Docker 状态
```bash
# Docker 服务状态
systemctl status docker

# Docker 版本
docker --version
docker compose version

# Docker 资源使用
docker stats

# Docker 磁盘使用
docker system df
```

### 检查容器状态
```bash
cd /root/dimensio/deploy/docker

# 容器状态
docker compose ps

# 所有容器（包括停止的）
docker compose ps -a

# 容器日志
docker compose logs -f

# 特定容器日志
docker compose logs -f backend
```

### 检查网络
```bash
# 测试本地连接
curl http://localhost:80
curl http://localhost:5000

# 测试外部连接
curl http://8.140.237.35

# 检查端口监听
netstat -tlnp | grep -E '80|5000|3000'

# 或者使用 ss
ss -tlnp | grep -E '80|5000|3000'
```

### 检查系统资源
```bash
# CPU 和内存
top
htop

# 磁盘空间
df -h

# 目录大小
du -sh /root/dimensio/*

# 检查进程
ps aux | grep docker
ps aux | grep nginx
```

---

## 🆘 需要帮助？

### 收集诊断信息

运行以下命令收集诊断信息：

```bash
#!/bin/bash
# 诊断信息收集脚本

echo "===== 系统信息 ====="
uname -a
cat /etc/os-release

echo -e "\n===== Docker 信息 ====="
docker --version
docker compose version
docker info

echo -e "\n===== 容器状态 ====="
cd /root/dimensio/deploy/docker
docker compose ps -a

echo -e "\n===== 最近日志 ====="
docker compose logs --tail=50

echo -e "\n===== 磁盘使用 ====="
df -h

echo -e "\n===== 端口监听 ====="
netstat -tlnp | grep -E '80|5000|3000'

echo -e "\n===== 防火墙状态 ====="
ufw status
```

将输出保存并查看：
```bash
bash collect-info.sh > diagnostic.log 2>&1
cat diagnostic.log
```

---

## 🔄 完全重置

如果问题无法解决，可以完全重置环境：

```bash
# 1. 停止所有容器
cd /root/dimensio/deploy/docker
docker compose down -v

# 2. 清理所有 Docker 资源
docker system prune -a --volumes -f

# 3. 备份数据（如果需要）
cd /root/dimensio
tar -czf backup-$(date +%Y%m%d).tar.gz data/ result/

# 4. 清理数据目录
rm -rf data/* result/* logs/*

# 5. 重新部署
cd /root/dimensio/deploy
sudo bash deploy.sh
```

---

## 📞 联系支持

如果以上方案都无法解决问题，请提供：

1. 诊断信息（使用上面的诊断脚本）
2. 完整的错误日志
3. 服务器配置信息
4. 已尝试的解决方案

这将帮助快速定位和解决问题。
