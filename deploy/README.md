# Dimensio 部署文档

基于 Docker + Nginx 的 Dimensio 自动化部署方案，适用于 Ubuntu 服务器。

## 📋 目录

- [系统要求](#系统要求)
- [部署架构](#部署架构)
- [快速部署](#快速部署)
- [详细说明](#详细说明)
- [常用命令](#常用命令)
- [故障排除](#故障排除)
- [更新部署](#更新部署)

## 🖥️ 系统要求

- **操作系统**: Ubuntu 18.04+ / Debian 10+
- **服务器IP**: 8.140.237.35
- **项目目录**: /root/dimensio
- **Python版本**: 3.9
- **系统权限**: Root 权限
- **最低配置**:
  - CPU: 2核
  - 内存: 4GB
  - 磁盘: 20GB 可用空间
- **网络**: 开放 80 端口（HTTP）

## 🏗️ 部署架构

```
Internet
    |
    v
[Nginx (Port 80)] - 反向代理 + 静态文件服务
    |
    +-- /api/* --> [Backend (Flask:5000)] - Python API服务
    |
    +-- /*     --> [Frontend (Port 3000)] - React前端应用
```

### 服务组件

| 组件 | 容器名称 | 端口 | 说明 |
|------|---------|------|------|
| Nginx | dimensio-nginx | 80 | 反向代理和负载均衡 |
| Backend | dimensio-backend | 5000 | Flask API服务 |
| Frontend | dimensio-frontend | 3000 | React前端应用 |

## 🚀 快速部署

### 方式一：一键部署（推荐）

```bash
# 1. 上传项目代码到服务器
# 将项目上传到 /root/dimensio 目录

# 2. 进入部署目录
cd /root/dimensio/deploy

# 3. 执行一键部署脚本
sudo bash deploy.sh
```

脚本会自动完成以下操作：
- ✅ 检查系统环境
- ✅ 安装 Docker 和 Docker Compose
- ✅ 创建必要的目录
- ✅ 构建 Docker 镜像
- ✅ 启动所有服务
- ✅ 验证服务状态
- ✅ 配置防火墙

### 方式二：手动部署

```bash
# 1. 安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 2. 安装 Docker Compose
sudo apt-get update
sudo apt-get install docker-compose-plugin

# 3. 进入项目目录
cd /root/dimensio

# 4. 创建必要的目录
mkdir -p data result logs
chmod 755 data result logs

# 5. 进入 docker 目录
cd deploy/docker

# 6. 构建并启动服务
docker compose build
docker compose up -d

# 7. 检查服务状态
docker compose ps
```

## 📖 详细说明

### 目录结构

```
dimensio/
├── deploy/                  # 部署配置目录
│   ├── docker/             # Docker 配置
│   │   ├── Dockerfile.backend      # 后端 Dockerfile
│   │   ├── Dockerfile.frontend     # 前端 Dockerfile
│   │   └── docker-compose.yml      # Docker Compose 配置
│   ├── nginx/              # Nginx 配置
│   │   ├── nginx.conf              # Nginx 主配置
│   │   ├── dimensio.conf           # 反向代理配置
│   │   └── default.conf            # 前端服务配置
│   ├── .env.example        # 环境变量示例
│   ├── deploy.sh           # 一键部署脚本
│   └── README.md           # 本文档
├── api/                    # 后端 API
├── front/                  # 前端应用
├── dimensio/              # 核心库
├── data/                  # 数据目录（运行时创建）
├── result/                # 结果目录（运行时创建）
└── logs/                  # 日志目录（运行时创建）
```

### 配置文件说明

#### docker-compose.yml

定义了三个服务：
- **backend**: Flask API服务，监听 5000 端口
- **frontend**: React前端应用，通过 Nginx 提供静态文件
- **nginx**: 反向代理服务器，监听 80 端口

#### Nginx 配置

- `nginx.conf`: Nginx 主配置文件，设置全局参数
- `dimensio.conf`: 反向代理配置，将请求路由到对应的服务
- `default.conf`: 前端服务配置，处理静态文件

## 🔧 常用命令

### 查看服务状态

```bash
cd /root/dimensio/deploy/docker
docker compose ps
```

### 查看日志

```bash
# 查看所有服务日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f backend
docker compose logs -f frontend
docker compose logs -f nginx
```

### 重启服务

```bash
# 重启所有服务
docker compose restart

# 重启特定服务
docker compose restart backend
docker compose restart frontend
docker compose restart nginx
```

### 停止服务

```bash
docker compose down
```

### 启动服务

```bash
docker compose up -d
```

### 重新构建并启动

```bash
# 重新构建镜像并启动（代码更新后使用）
docker compose up -d --build

# 不使用缓存重新构建
docker compose build --no-cache
docker compose up -d
```

### 清理资源

```bash
# 停止并删除容器、网络
docker compose down

# 清理未使用的镜像
docker image prune -f

# 清理所有未使用的资源
docker system prune -a
```

### 进入容器

```bash
# 进入后端容器
docker exec -it dimensio-backend bash

# 进入前端容器
docker exec -it dimensio-frontend sh

# 进入 Nginx 容器
docker exec -it dimensio-nginx sh
```

## 🔍 服务访问

部署完成后，可以通过以下地址访问服务：

| 服务 | 地址 | 说明 |
|------|------|------|
| 前端应用 | http://8.140.237.35 | React 应用界面 |
| 后端API | http://8.140.237.35/api/ | API 文档 |
| 健康检查 | http://8.140.237.35/health | 服务健康状态 |
| API上传 | http://8.140.237.35/api/upload | 文件上传接口 |
| 压缩历史 | http://8.140.237.35/api/compression/history | 获取压缩历史 |

### API 测试

```bash
# 测试 API 服务
curl http://8.140.237.35/api/

# 测试健康检查
curl http://8.140.237.35/health

# 查看压缩历史
curl http://8.140.237.35/api/compression/history
```

## ⚠️ 故障排除

### 0. Docker 镜像拉取失败（重要）

**问题**:
- `dial tcp: i/o timeout`
- `failed to resolve source metadata`
- `not found` 或 `connection reset by peer`

这是在中国大陆访问 Docker Hub 时的常见问题。

**解决方案**:

```bash
# 方法一：使用修复脚本（推荐）
cd /root/dimensio/deploy
sudo bash fix-docker-registry.sh

# 等待 Docker 重启完成后，重新运行部署脚本
sudo bash deploy.sh
```

**方法二：手动配置镜像加速器**

```bash
# 1. 编辑 Docker 配置文件
sudo vim /etc/docker/daemon.json

# 2. 添加以下内容（如果文件已存在，合并配置）
{
  "registry-mirrors": [
    "https://docker.1panel.live",
    "https://docker.1ms.run",
    "https://docker.nju.edu.cn",
    "https://docker.mirrors.sjtug.sjtu.edu.cn",
    "https://hub.rat.dev",
    "https://docker.m.daocloud.io",
    "https://dockerproxy.net",
    "https://docker.mirrors.ustc.edu.cn"
  ],
  "max-concurrent-downloads": 10
}

# 3. 重启 Docker 服务
sudo systemctl daemon-reload
sudo systemctl restart docker

# 4. 验证配置
docker info | grep -A 10 "Registry Mirrors"

# 5. 重新运行部署脚本
cd /root/dimensio/deploy
sudo bash deploy.sh
```

**方法三：手动拉取镜像**

如果镜像源仍然不可用，可以尝试手动拉取：

```bash
# 拉取所需的基础镜像
docker pull python:3.9-slim
docker pull node:18-alpine
docker pull nginx:alpine

# 然后重新构建
cd /root/dimensio/deploy/docker
docker compose build
docker compose up -d
```

**可用的镜像源列表**（按推荐顺序）：

| 镜像源 | 地址 | 说明 |
|--------|------|------|
| 1Panel | https://docker.1panel.live | 限制中国地区，速度快 |
| 毫秒镜像 | https://docker.1ms.run | 稳定可靠 |
| 南京大学 | https://docker.nju.edu.cn | 教育网友好 |
| 上海交大 | https://docker.mirrors.sjtug.sjtu.edu.cn | 速度快 |
| Rat Dev | https://hub.rat.dev | 新兴镜像源 |
| DaoCloud | https://docker.m.daocloud.io | 老牌镜像源 |
| Docker Proxy | https://dockerproxy.net | 备选方案 |
| 中科大 | https://docker.mirrors.ustc.edu.cn | 稳定性好 |

### 1. 端口冲突

**问题**: 80 端口被占用

**解决方案**:
```bash
# 查看占用端口的进程
sudo lsof -i :80

# 停止占用端口的服务
sudo systemctl stop nginx  # 如果是系统 Nginx
sudo systemctl stop apache2  # 如果是 Apache
```

### 2. Docker 服务未启动

**问题**: Cannot connect to the Docker daemon

**解决方案**:
```bash
# 启动 Docker 服务
sudo systemctl start docker

# 设置开机自启
sudo systemctl enable docker
```

### 3. 容器启动失败

**问题**: 容器状态为 Exited 或 Restarting

**解决方案**:
```bash
# 查看详细日志
cd /root/dimensio/deploy/docker
docker compose logs backend
docker compose logs frontend
docker compose logs nginx

# 检查配置文件
cat docker-compose.yml

# 重新构建容器
docker compose down
docker compose up -d --build
```

### 4. 前端无法访问后端

**问题**: API 请求失败

**解决方案**:
```bash
# 检查网络连通性
docker compose exec frontend ping backend

# 检查 Nginx 配置
docker compose exec nginx nginx -t

# 重启 Nginx
docker compose restart nginx
```

### 5. Python 依赖安装失败

**问题**: pip install 失败

**解决方案**:
```bash
# 使用国内镜像源
# 在 Dockerfile.backend 中添加：
# RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# 重新构建
docker compose build --no-cache backend
docker compose up -d
```

### 6. 磁盘空间不足

**问题**: No space left on device

**解决方案**:
```bash
# 查看磁盘使用情况
df -h

# 清理 Docker 资源
docker system prune -a --volumes

# 清理日志文件
sudo find /var/lib/docker -name "*.log" -exec truncate -s 0 {} \;
```

### 7. 防火墙阻止访问

**问题**: 无法从外部访问服务

**解决方案**:
```bash
# 检查防火墙状态
sudo ufw status

# 允许 80 端口
sudo ufw allow 80/tcp

# 如果使用阿里云等云服务器，还需要在安全组中开放 80 端口
```

## 🔄 更新部署

### 更新代码

```bash
# 1. 进入项目目录
cd /root/dimensio

# 2. 拉取最新代码（如果使用 Git）
git pull origin main

# 3. 停止当前服务
cd deploy/docker
docker compose down

# 4. 重新构建并启动
docker compose up -d --build

# 5. 验证服务
docker compose ps
curl http://localhost/api/
```

### 更新配置

```bash
# 1. 修改配置文件
vim deploy/nginx/dimensio.conf

# 2. 重新加载 Nginx 配置
docker compose restart nginx

# 或者重新构建
docker compose up -d --build nginx
```

## 📊 监控与维护

### 查看资源使用

```bash
# 查看容器资源使用情况
docker stats

# 查看磁盘使用
du -sh /root/dimensio/*
```

### 日志管理

```bash
# 限制日志大小（在 docker-compose.yml 中配置）
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

### 定期备份

```bash
# 备份数据目录
tar -czf dimensio-data-$(date +%Y%m%d).tar.gz /root/dimensio/data
tar -czf dimensio-result-$(date +%Y%m%d).tar.gz /root/dimensio/result

# 备份到远程服务器（可选）
scp dimensio-*.tar.gz user@backup-server:/backup/
```

## 🔐 安全建议

1. **使用 HTTPS**: 配置 SSL/TLS 证书（Let's Encrypt）
2. **限制访问**: 配置 IP 白名单或使用 VPN
3. **定期更新**: 及时更新 Docker 和系统补丁
4. **强密码**: 如果添加认证，使用强密码
5. **监控日志**: 定期检查日志文件，发现异常行为

## 📝 环境变量

在 `deploy/.env.example` 中查看所有可配置的环境变量：

```bash
# 复制环境变量文件
cp deploy/.env.example deploy/.env

# 编辑环境变量
vim deploy/.env
```

## 🆘 获取帮助

如果遇到问题：

1. 查看日志: `docker compose logs -f`
2. 检查容器状态: `docker compose ps`
3. 查看本文档的故障排除部分
4. 检查 Docker 和系统日志: `journalctl -u docker`

## 📜 许可证

本部署方案遵循项目主许可证。

---

**部署成功后，访问 http://8.140.237.35 即可使用 Dimensio 服务！**
