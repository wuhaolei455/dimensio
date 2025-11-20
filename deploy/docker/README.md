# Docker 部署方式

使用 Docker 容器化部署 Dimensio 项目。

## 快速开始

### 1. 安装 Docker

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 安装 Docker Compose
sudo apt install docker-compose-plugin
```

### 1.5 配置国内镜像源（国内用户推荐）

**如果你在中国大陆，强烈建议配置镜像源以加速构建：**

```bash
cd /path/to/dimensio/deploy/docker

# 运行镜像源配置脚本
sudo ./setup-docker-mirror.sh
```

该脚本会：
- 自动配置 Docker daemon 使用国内镜像源
- 备份现有配置（如果有）
- 重启 Docker 服务使配置生效

**可用的镜像源包括：**
- docker.1panel.live - 1Panel 镜像（推荐）
- docker.1ms.run - 毫秒镜像
- docker.nju.edu.cn - 南京大学
- docker.mirrors.sjtug.sjtu.edu.cn - 上海交通大学
- hub.rat.dev - Rat 开发镜像
- docker.m.daocloud.io - DaoCloud
- dockerproxy.net - Docker 代理
- docker.mirrors.ustc.edu.cn - 中国科技大学

**如果希望禁用国内镜像源：**

编辑 `docker-compose.yml`，将 `USE_CN_MIRROR` 设置为 `false`：

```yaml
services:
  dimensio-api:
    build:
      args:
        USE_CN_MIRROR: "false"  # 改为 false
```

### 2. 构建和启动

```bash
cd /path/to/dimensio/deploy/docker

# 构建镜像
docker-compose build

# 启动服务
docker-compose up -d
```

### 3. 验证部署

```bash
# 查看运行状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 测试 API
curl http://localhost:5000/

# 浏览器访问
# http://localhost
```

## 常用命令

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看日志
docker-compose logs -f dimensio-api    # API 日志
docker-compose logs -f nginx            # Nginx 日志

# 进入容器
docker-compose exec dimensio-api bash

# 查看状态
docker-compose ps
```

## 数据持久化

数据卷（Volumes）：
- `dimensio-data`: 上传的数据文件
- `dimensio-results`: 压缩结果
- `dimensio-logs`: 日志文件

查看数据卷：
```bash
docker volume ls
docker volume inspect dimensio-data
```

## 备份和恢复

### 备份

```bash
# 备份数据卷
docker run --rm -v dimensio-data:/data -v $(pwd):/backup \
    alpine tar czf /backup/dimensio-data-backup.tar.gz -C /data .

docker run --rm -v dimensio-results:/data -v $(pwd):/backup \
    alpine tar czf /backup/dimensio-results-backup.tar.gz -C /data .
```

### 恢复

```bash
# 恢复数据卷
docker run --rm -v dimensio-data:/data -v $(pwd):/backup \
    alpine tar xzf /backup/dimensio-data-backup.tar.gz -C /data

docker run --rm -v dimensio-results:/data -v $(pwd):/backup \
    alpine tar xzf /backup/dimensio-results-backup.tar.gz -C /data
```

## 自定义配置

### 修改端口

编辑 `docker-compose.yml`：

```yaml
services:
  dimensio-api:
    ports:
      - "8080:5000"  # 修改为 8080

  nginx:
    ports:
      - "8000:80"    # 修改为 8000
```

### 增加 Worker 数量

编辑 `Dockerfile`，修改启动命令：

```dockerfile
CMD ["gunicorn", "--bind", "0.0.0.0:5000", \
     "--workers", "8", \              # 修改这里
     "--threads", "2", \
     ...
```

### 配置 HTTPS

1. 将 SSL 证书放到 `deploy/docker/ssl/` 目录
2. 修改 `docker-compose.yml`，取消 SSL 卷挂载的注释
3. 修改 `nginx.conf`，添加 HTTPS 配置

## 更新镜像

```bash
# 停止服务
docker-compose down

# 拉取最新代码
cd /path/to/dimensio
git pull

# 重新构建镜像
cd deploy/docker
docker-compose build

# 启动服务
docker-compose up -d
```

## 监控和日志

### 查看资源使用

```bash
# 查看容器资源使用
docker stats

# 查看特定容器
docker stats dimensio-api dimensio-nginx
```

### 日志管理

```bash
# 实时查看日志
docker-compose logs -f --tail=100

# 查看特定服务日志
docker-compose logs dimensio-api

# 导出日志
docker-compose logs > dimensio-logs.txt
```

## 故障排查

### Docker 镜像拉取失败

如果遇到 `dial tcp: i/o timeout` 或 `not found` 错误：

```bash
# 1. 配置镜像源
sudo ./setup-docker-mirror.sh

# 2. 验证镜像源配置
docker info | grep -A 8 "Registry Mirrors:"

# 3. 重新构建（使用国内镜像源）
docker-compose build --no-cache
```

### 容器无法启动

```bash
# 查看详细错误
docker-compose logs dimensio-api

# 检查容器状态
docker-compose ps
docker inspect dimensio-api
```

### 进入容器调试

```bash
# 进入 API 容器
docker-compose exec dimensio-api bash

# 查看进程
ps aux | grep gunicorn

# 查看端口
netstat -tlnp
```

### 清理和重建

```bash
# 完全清理（会删除数据卷！）
docker-compose down -v

# 清理镜像
docker system prune -a

# 重新构建
docker-compose build --no-cache
docker-compose up -d
```

## 生产环境建议

1. **资源限制**: 在 `docker-compose.yml` 中添加资源限制

```yaml
services:
  dimensio-api:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

2. **健康检查**: 已配置健康检查，可以查看状态

```bash
docker-compose ps
```

3. **日志轮转**: 配置 Docker 日志驱动

```yaml
services:
  dimensio-api:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

4. **使用 Swarm 或 Kubernetes**: 对于高可用部署，考虑使用容器编排工具

## 与传统部署对比

| 特性 | Docker 部署 | 传统部署 |
|------|------------|---------|
| 安装速度 | ⚡ 快 | 🐢 慢 |
| 环境一致性 | ✅ 完全一致 | ⚠️ 可能不同 |
| 资源隔离 | ✅ 容器隔离 | ❌ 共享系统 |
| 扩展性 | ✅ 易于扩展 | ⚠️ 手动配置 |
| 回滚 | ✅ 秒级回滚 | ⚠️ 需要手动 |
| 学习成本 | 📚 需要学 Docker | ✅ 传统运维 |

根据你的需求选择合适的部署方式！
