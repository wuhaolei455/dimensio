# Dimensio 多环境部署指南

本项目支持两种部署环境：**本地开发环境**和**生产环境**。每个环境都有独立的配置文件和部署脚本。

---

## 📋 目录

- [环境概述](#环境概述)
- [本地开发环境](#本地开发环境)
- [生产环境](#生产环境)
- [环境配置文件](#环境配置文件)
- [Docker Compose 配置](#docker-compose-配置)
- [常见问题](#常见问题)

---

## 环境概述

### 🏠 本地开发环境 (Local)

- **用途**: 本地开发、测试、调试
- **特点**:
  - 使用非标准端口（避免与本地其他服务冲突）
  - 支持代码热重载
  - 详细的调试日志
  - 不需要 Docker 镜像加速
  - 挂载源代码目录

- **默认端口**:
  - Backend: `5001`
  - Frontend: `3001`
  - Nginx: `8080`

### 🚀 生产环境 (Production)

- **用途**: 服务器生产部署
- **特点**:
  - 使用标准端口
  - 优化的构建和性能
  - 生产级日志
  - 支持中国镜像加速
  - 健康检查和自动重启

- **默认端口**:
  - Backend: `5000`
  - Frontend: `3000`
  - Nginx: `80`

---

## 本地开发环境

### 快速开始

```bash
# 1. 进入部署目录
cd deploy

# 2. 运行本地部署脚本
bash deploy-local.sh
```

### 详细步骤

#### 1. 配置环境变量

复制并编辑本地环境配置：

```bash
cd deploy
cp .env.local .env.local.custom  # 可选：自定义配置
```

编辑 `.env.local`（可选）：

```bash
# 修改端口（如果默认端口被占用）
BACKEND_PORT=5001
FRONTEND_PORT=3001
NGINX_PORT=8080

# 日志级别
LOG_LEVEL=DEBUG
```

#### 2. 启动服务

```bash
# 方式 1：使用部署脚本（推荐）
bash deploy-local.sh

# 方式 2：手动启动
cd docker
docker-compose -f docker-compose.local.yml up -d --build
```

#### 3. 访问服务

- **前端应用**: http://localhost:8080
- **后端 API**: http://localhost:5001
- **API 文档**: http://localhost:5001/

#### 4. 查看日志

```bash
cd deploy/docker

# 查看所有服务日志
docker-compose -f docker-compose.local.yml logs -f

# 查看特定服务日志
docker-compose -f docker-compose.local.yml logs -f backend
docker-compose -f docker-compose.local.yml logs -f frontend
docker-compose -f docker-compose.local.yml logs -f nginx
```

#### 5. 停止服务

```bash
cd deploy/docker
docker-compose -f docker-compose.local.yml down
```

### 本地开发特性

#### 代码热重载

本地环境挂载了源代码目录，修改代码后会自动重新加载：

- **后端**: 修改 `api/` 或 `dimensio/` 目录下的 Python 代码
- **前端**: 修改 `front/src/` 目录下的 TypeScript/React 代码

#### 调试模式

- Flask 运行在调试模式 (`FLASK_ENV=development`)
- 详细的错误堆栈信息
- 自动重载

---

## 生产环境

### 快速开始

```bash
# 在服务器上执行
cd deploy
sudo bash deploy-production.sh
```

### 详细步骤

#### 1. 配置环境变量

编辑生产环境配置：

```bash
cd deploy
vim .env.production
```

**必须修改的配置**：

```bash
# 修改为你的服务器 IP 或域名
SERVER_IP=8.140.237.35
SERVER_NAME=8.140.237.35

# 或者使用域名
# SERVER_IP=dimensio.example.com
# SERVER_NAME=dimensio.example.com
```

#### 2. 部署到服务器

```bash
# 方式 1：使用部署脚本（推荐）
sudo bash deploy-production.sh

# 方式 2：手动部署
cd docker
docker-compose -f docker-compose.production.yml up -d --build
```

部署脚本会自动：
1. 检查 Docker 安装
2. 配置 Docker 镜像加速（中国服务器）
3. 检查并释放端口
4. 创建必要的目录
5. 构建并启动容器
6. 健康检查

#### 3. 访问服务

- **前端应用**: http://your-server-ip
- **后端 API**: http://your-server-ip:5000
- **API 文档**: http://your-server-ip/api

#### 4. 监控服务

```bash
cd deploy/docker

# 查看容器状态
docker-compose -f docker-compose.production.yml ps

# 查看日志
docker-compose -f docker-compose.production.yml logs -f

# 查看资源使用
docker stats
```

#### 5. 管理服务

```bash
cd deploy/docker

# 重启服务
docker-compose -f docker-compose.production.yml restart

# 停止服务
docker-compose -f docker-compose.production.yml stop

# 启动服务
docker-compose -f docker-compose.production.yml start

# 完全移除（包括卷）
docker-compose -f docker-compose.production.yml down -v
```

---

## 环境配置文件

### 配置文件对比

| 配置项 | 本地开发 (`.env.local`) | 生产环境 (`.env.production`) |
|-------|------------------------|----------------------------|
| `ENV` | `local` | `production` |
| `SERVER_IP` | `localhost` | 服务器 IP/域名 |
| `BACKEND_PORT` | `5001` | `5000` |
| `FRONTEND_PORT` | `3001` | `3000` |
| `NGINX_PORT` | `8080` | `80` |
| `FLASK_ENV` | `development` | `production` |
| `LOG_LEVEL` | `DEBUG` | `INFO` |
| `USE_DOCKER_MIRROR` | `false` | `true` |
| `ENABLE_HOT_RELOAD` | `true` | `false` |

### .env.local（本地开发）

```bash
# 环境类型
ENV=local

# 服务器配置
SERVER_IP=localhost
SERVER_NAME=localhost
PROJECT_DIR=.

# 应用配置
FLASK_APP=api/server.py
FLASK_ENV=development
PYTHONUNBUFFERED=1

# 端口配置（避免冲突）
BACKEND_PORT=5001
FRONTEND_PORT=3001
NGINX_PORT=8080

# Docker 配置
COMPOSE_PROJECT_NAME=dimensio-local

# Python 版本
PYTHON_VERSION=3.9

# 日志
LOG_LEVEL=DEBUG

# Docker 镜像源（本地不需要）
USE_DOCKER_MIRROR=false

# 热重载（本地启用）
ENABLE_HOT_RELOAD=true
```

### .env.production（生产环境）

```bash
# 环境类型
ENV=production

# 服务器配置
SERVER_IP=8.140.237.35
SERVER_NAME=8.140.237.35
PROJECT_DIR=/root/dimensio

# 应用配置
FLASK_APP=api/server.py
FLASK_ENV=production
PYTHONUNBUFFERED=1

# 端口配置（标准端口）
BACKEND_PORT=5000
FRONTEND_PORT=3000
NGINX_PORT=80

# Docker 配置
COMPOSE_PROJECT_NAME=dimensio

# Python 版本
PYTHON_VERSION=3.9

# 日志
LOG_LEVEL=INFO

# Docker 镜像源（生产启用）
USE_DOCKER_MIRROR=true

# 热重载（生产禁用）
ENABLE_HOT_RELOAD=false
```

---

## Docker Compose 配置

### 配置文件说明

| 文件 | 用途 | 环境 |
|------|------|------|
| `docker-compose.yml` | 通用配置（已弃用） | - |
| `docker-compose.local.yml` | 本地开发配置 | Local |
| `docker-compose.production.yml` | 生产环境配置 | Production |

### 关键差异

#### 本地开发 (docker-compose.local.yml)

```yaml
services:
  backend:
    ports:
      - "${BACKEND_PORT:-5001}:5000"
    volumes:
      # 挂载源代码支持热重载
      - ../../api:/app/api
      - ../../dimensio:/app/dimensio
    environment:
      - FLASK_ENV=development
    command: python -m flask run --host=0.0.0.0 --port=5000 --reload

  frontend:
    build:
      target: development  # 开发模式构建
    volumes:
      # 挂载前端代码
      - ../../front/src:/app/src
```

#### 生产环境 (docker-compose.production.yml)

```yaml
services:
  backend:
    ports:
      - "${BACKEND_PORT:-5000}:5000"
    environment:
      - FLASK_ENV=production
    healthcheck:
      test: ["CMD", "python", "-c", "import requests; requests.get('http://localhost:5000/')"]
      interval: 30s
      timeout: 10s
      retries: 3

  frontend:
    build:
      # 生产模式构建（优化）
    # 不挂载源代码
```

---

## 常见问题

### 本地开发问题

#### Q1: 端口被占用怎么办？

**方法 1**：修改 `.env.local` 中的端口

```bash
BACKEND_PORT=5002
FRONTEND_PORT=3002
NGINX_PORT=8081
```

**方法 2**：停止占用端口的进程

```bash
# macOS/Linux
lsof -ti:8080 | xargs kill -9

# 或使用 deploy-local.sh 自动处理
bash deploy-local.sh
```

#### Q2: 如何重新构建镜像？

```bash
cd deploy/docker
docker-compose -f docker-compose.local.yml up -d --build --force-recreate
```

#### Q3: 如何清理所有数据？

```bash
cd deploy/docker
docker-compose -f docker-compose.local.yml down -v
rm -rf ../../data/* ../../result/* ../../logs/*
```

### 生产环境问题

#### Q1: Docker 镜像拉取超时

```bash
# 运行镜像源配置脚本
cd deploy
sudo bash fix-docker-registry.sh

# 然后重新部署
sudo bash deploy-production.sh
```

#### Q2: 80 端口被占用

```bash
# 使用端口清理脚本
cd deploy
sudo bash free-ports.sh

# 或手动停止系统 Nginx
sudo systemctl stop nginx
sudo systemctl disable nginx
```

#### Q3: 如何查看详细错误日志？

```bash
cd deploy/docker

# 查看后端错误
docker-compose -f docker-compose.production.yml logs backend | grep -i error

# 查看容器内的日志文件
docker exec dimensio-backend cat /app/logs/app.log
```

#### Q4: 如何更新代码？

```bash
# 1. 拉取最新代码
git pull

# 2. 重新构建并部署
cd deploy
sudo bash deploy-production.sh
```

---

## 快速参考

### 本地开发

```bash
# 启动
cd deploy && bash deploy-local.sh

# 查看日志
cd deploy/docker && docker-compose -f docker-compose.local.yml logs -f

# 停止
cd deploy/docker && docker-compose -f docker-compose.local.yml down

# 访问
open http://localhost:8080
```

### 生产环境

```bash
# 部署
cd deploy && sudo bash deploy-production.sh

# 查看状态
cd deploy/docker && docker-compose -f docker-compose.production.yml ps

# 重启
cd deploy/docker && docker-compose -f docker-compose.production.yml restart

# 查看日志
cd deploy/docker && docker-compose -f docker-compose.production.yml logs -f
```

---

## 相关文档

- [README.md](README.md) - 完整部署文档
- [QUICKSTART.md](QUICKSTART.md) - 快速开始指南
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - 故障排除
- [FILES.md](FILES.md) - 文件清单
- [../TROUBLESHOOT.md](../TROUBLESHOOT.md) - 综合故障排除指南

---

## 总结

| 场景 | 使用环境 | 命令 |
|------|---------|------|
| 本地开发测试 | Local | `bash deploy-local.sh` |
| 服务器生产部署 | Production | `sudo bash deploy-production.sh` |
| 快速原型验证 | Local | `bash deploy-local.sh` |
| 正式对外服务 | Production | `sudo bash deploy-production.sh` |
