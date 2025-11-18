# Dimensio 部署快速指南

根据你的使用场景选择对应的部署方式。

---

## 🏠 本地开发（macOS/Linux/Windows）

### 适用场景
- 本地开发和测试
- 代码调试
- 功能验证

### 一键部署

```bash
cd deploy
bash deploy-local.sh
```

### 访问地址
- **前端**: http://localhost:8080
- **后端**: http://localhost:5001
- **API**: http://localhost:8080/api

### 特点
- ✅ 使用非标准端口（避免冲突）
- ✅ 支持代码热重载
- ✅ 详细的调试日志
- ✅ 修改代码立即生效

### 常用命令

```bash
# 查看日志
cd deploy/docker
docker-compose -f docker-compose.local.yml logs -f

# 停止服务
docker-compose -f docker-compose.local.yml down

# 重启服务
docker-compose -f docker-compose.local.yml restart
```

---

## 🚀 服务器生产部署（Linux）

### 适用场景
- 生产环境
- 对外提供服务
- 正式部署

### 一键部署

```bash
cd deploy
sudo bash deploy-production.sh
```

### 访问地址
- **前端**: http://your-server-ip
- **后端**: http://your-server-ip:5000
- **API**: http://your-server-ip/api

### 配置服务器 IP

部署前先修改配置：

```bash
cd deploy
vim .env.production
```

修改这一行：
```bash
SERVER_IP=8.140.237.35  # 改为你的服务器 IP
```

### 特点
- ✅ 使用标准端口（80, 5000, 3000）
- ✅ 自动配置 Docker 镜像加速
- ✅ 自动清理端口冲突
- ✅ 健康检查和自动重启

### 常用命令

```bash
# 查看状态
cd deploy/docker
docker-compose -f docker-compose.production.yml ps

# 查看日志
docker-compose -f docker-compose.production.yml logs -f

# 重启服务
docker-compose -f docker-compose.production.yml restart

# 停止服务
docker-compose -f docker-compose.production.yml down
```

---

## 📊 环境对比

| 特性 | 本地开发 | 生产环境 |
|------|---------|---------|
| **部署命令** | `bash deploy-local.sh` | `sudo bash deploy-production.sh` |
| **前端地址** | http://localhost:8080 | http://your-server-ip |
| **后端端口** | 5001 | 5000 |
| **Nginx 端口** | 8080 | 80 |
| **代码热重载** | ✅ 支持 | ❌ 不支持 |
| **日志级别** | DEBUG | INFO |
| **Docker 镜像加速** | ❌ 不需要 | ✅ 自动配置 |
| **需要 sudo** | ❌ | ✅ |

---

## 🔧 常见问题

### 本地开发

**Q: 端口被占用怎么办？**

编辑 `deploy/.env.local` 修改端口：
```bash
BACKEND_PORT=5002
NGINX_PORT=8081
```

**Q: 如何查看后端日志？**

```bash
cd deploy/docker
docker-compose -f docker-compose.local.yml logs -f backend
```

### 生产部署

**Q: Docker 拉取镜像超时？**

```bash
cd deploy
sudo bash fix-docker-registry.sh
```

**Q: 80 端口被系统 Nginx 占用？**

```bash
cd deploy
sudo bash free-ports.sh
```

**Q: 如何更新代码？**

```bash
git pull
cd deploy
sudo bash deploy-production.sh
```

---

## 📚 详细文档

- **[ENVIRONMENTS.md](deploy/ENVIRONMENTS.md)** - 完整的多环境部署指南
- **[TROUBLESHOOT.md](TROUBLESHOOT.md)** - 故障排除指南
- **[deploy/README.md](deploy/README.md)** - 详细部署文档
- **[deploy/QUICKSTART.md](deploy/QUICKSTART.md)** - 快速开始

---

## 🎯 推荐流程

### 开发者工作流

1. **本地开发**
   ```bash
   bash deploy/deploy-local.sh
   # 开发和测试...
   ```

2. **提交代码**
   ```bash
   git add .
   git commit -m "feat: new feature"
   git push
   ```

3. **服务器部署**
   ```bash
   # SSH 到服务器
   ssh user@server
   cd /path/to/dimensio
   git pull
   sudo bash deploy/deploy-production.sh
   ```

### 首次使用

1. **克隆代码**
   ```bash
   git clone https://github.com/your-repo/dimensio.git
   cd dimensio
   ```

2. **本地测试**
   ```bash
   bash deploy/deploy-local.sh
   # 访问 http://localhost:8080 测试
   ```

3. **服务器部署**
   ```bash
   # 修改生产配置
   vim deploy/.env.production
   # 部署
   sudo bash deploy/deploy-production.sh
   ```

---

## ⚡ 快速命令

### 本地开发
```bash
# 启动
bash deploy/deploy-local.sh

# 停止
cd deploy/docker && docker-compose -f docker-compose.local.yml down
```

### 生产环境
```bash
# 启动
sudo bash deploy/deploy-production.sh

# 停止
cd deploy/docker && docker-compose -f docker-compose.production.yml down
```

---

**需要帮助？** 查看 [TROUBLESHOOT.md](TROUBLESHOOT.md) 或提交 Issue。
