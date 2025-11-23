# 🔧 端口冲突修复指南

## 问题描述

```
ERROR: failed to bind host port 0.0.0.0:80/tcp: address already in use
```

**原因：** 端口 80 已经被其他程序占用（通常是系统的 Nginx 或 Apache）。

---

## 🚀 快速修复

### 方法 1: 使用自动清理脚本（推荐）

```bash
cd /root/dimensio/deploy
./free-ports.sh
```

**这个脚本会：**
- ✅ 检查端口 80、5000、3000 的占用情况
- ✅ 显示占用进程的详细信息
- ✅ 询问是否停止占用进程
- ✅ 自动清理端口

---

### 方法 2: 手动清理（如果脚本不可用）

#### 步骤 1: 查找占用端口 80 的进程

```bash
# 方法 A: 使用 lsof
lsof -i:80

# 方法 B: 使用 netstat
netstat -tlnp | grep :80

# 方法 C: 使用 ss
ss -tlnp | grep :80
```

**示例输出：**
```
COMMAND   PID  USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
nginx    1234  root    6u  IPv4  12345      0t0  TCP *:80 (LISTEN)
```

#### 步骤 2: 停止占用进程

**如果是系统 Nginx：**
```bash
# 停止系统 Nginx
systemctl stop nginx

# 或
service nginx stop

# 禁止开机自启（可选）
systemctl disable nginx
```

**如果是其他进程：**
```bash
# 使用步骤1中找到的 PID
kill -9 <PID>

# 例如：
kill -9 1234
```

#### 步骤 3: 验证端口已释放

```bash
# 检查端口 80
lsof -i:80
# 应该没有输出

# 或
netstat -tlnp | grep :80
# 应该没有输出
```

---

## 📋 检查所有需要的端口

Dimensio 需要以下端口：

| 端口 | 用途 | 检查命令 |
|------|------|----------|
| 80 | Nginx (主入口) | `lsof -i:80` |
| 5000 | Backend API | `lsof -i:5000` |
| 3000 | Frontend (可选) | `lsof -i:3000` |

**批量检查：**
```bash
echo "=== Port 80 ===" && lsof -i:80
echo "=== Port 5000 ===" && lsof -i:5000
echo "=== Port 3000 ===" && lsof -i:3000
```

---

## 🔍 常见占用场景

### 场景 1: 系统 Nginx 占用端口 80

**解决：**
```bash
# 停止系统 Nginx
systemctl stop nginx

# 验证
systemctl status nginx
# 应该显示 "inactive (dead)"
```

### 场景 2: Apache 占用端口 80

**解决：**
```bash
# 停止 Apache
systemctl stop apache2  # Debian/Ubuntu
# 或
systemctl stop httpd    # CentOS/RHEL

# 验证
systemctl status apache2
```

### 场景 3: 旧的 Docker 容器占用端口

**解决：**
```bash
# 停止所有容器
docker stop $(docker ps -q)

# 或只停止 Dimensio 相关容器
docker stop dimensio-nginx dimensio-backend dimensio-frontend

# 删除容器
docker-compose down
```

### 场景 4: 其他未知进程

**解决：**
```bash
# 1. 找到进程
lsof -i:80

# 2. 查看进程详情
ps -p <PID> -f

# 3. 停止进程
kill -9 <PID>
```

---

## ⚠️ 重要提示

### 如果是生产服务器

在停止系统 Nginx 之前，确认：

1. **系统 Nginx 是否在运行其他网站？**
   ```bash
   # 查看 Nginx 配置
   ls -la /etc/nginx/sites-enabled/
   cat /etc/nginx/nginx.conf
   ```

2. **是否有其他服务依赖 Nginx？**
   - 如果有，考虑修改 Docker 端口而不是停止系统 Nginx

### 修改 Docker 端口（替代方案）

如果不想停止系统 Nginx，可以修改 Docker 映射端口：

**编辑 `docker/docker-compose.yml`：**
```yaml
services:
  nginx:
    ports:
      - "8080:80"  # 改为 8080 或其他可用端口
```

**然后访问：**
```
http://8.140.237.35:8080/
```

---

## ✅ 验证修复

修复后，验证端口已释放：

```bash
# 应该没有输出
lsof -i:80
lsof -i:5000
lsof -i:3000

# 或看到 "not found"
netstat -tlnp | grep -E ":(80|5000|3000) "
```

---

## 🚀 修复后继续部署

```bash
cd /root/dimensio/deploy
./deploy-docker-only.sh
```

**或者重新尝试启动：**
```bash
cd /root/dimensio/deploy/docker
docker-compose up -d
```

---

## 🆘 还是失败？

### 获取详细错误信息

```bash
# 查看 Docker Compose 日志
cd /root/dimensio/deploy/docker
docker-compose logs nginx

# 查看系统日志
journalctl -xe | grep -i port

# 检查 Docker 网络
docker network ls
docker network inspect docker_dimensio-network
```

### 完全重置

如果问题持续，尝试完全重置：

```bash
# 1. 停止所有容器
docker-compose down

# 2. 删除所有 Dimensio 容器
docker rm -f $(docker ps -a | grep dimensio | awk '{print $1}')

# 3. 删除网络
docker network rm docker_dimensio-network 2>/dev/null

# 4. 停止占用端口的进程
systemctl stop nginx

# 5. 清理端口
./free-ports.sh

# 6. 重新部署
./deploy-docker-only.sh
```

---

## 📊 诊断命令汇总

```bash
# 检查端口
lsof -i:80
netstat -tlnp | grep :80

# 检查系统服务
systemctl status nginx
systemctl status apache2

# 检查 Docker
docker ps
docker-compose ps

# 检查网络
docker network ls

# 停止服务
systemctl stop nginx
docker-compose down

# 清理端口
./free-ports.sh
```

---

## 🎯 总结

**端口冲突的常见原因：**
1. ✅ 系统 Nginx 在运行
2. ✅ 旧的 Docker 容器未清理
3. ✅ 其他 Web 服务器（Apache、Caddy 等）

**快速修复：**
```bash
# 1. 清理端口
cd /root/dimensio/deploy
./free-ports.sh

# 2. 重新部署
./deploy-docker-only.sh
```

**如果还是失败，发送以下信息：**
```bash
lsof -i:80
systemctl status nginx
docker ps -a
```

---

**现在运行 `./free-ports.sh` 清理端口！** 🚀
