# Dimensio Docker 部署故障排除指南

本文档整理了 Dimensio Docker 部署过程中遇到的所有常见问题及解决方案。

---

## 目录

1. [Docker 镜像拉取问题](#1-docker-镜像拉取问题)
2. [端口冲突问题](#2-端口冲突问题)
3. [前端构建错误](#3-前端构建错误)
4. [CORS 跨域问题](#4-cors-跨域问题)
5. [文件上传大小限制](#5-文件上传大小限制)
6. [Result 目录为空](#6-result-目录为空)
7. [Debian 镜像源问题](#7-debian-镜像源问题)
8. [快速诊断脚本](#8-快速诊断脚本)

---

## 1. Docker 镜像拉取问题

### 问题症状

```
ERROR [backend internal] load metadata for docker.io/library/python:3.9-slim
dial tcp 198.44.185.131:443: i/o timeout
```

### 原因

在中国大陆访问 Docker Hub 会非常慢或超时。

### 解决方案 1：使用自动修复脚本（推荐）

```bash
cd deploy
sudo bash fix-docker-registry.sh
```

脚本会自动配置多个可靠的中国镜像源并重启 Docker 服务。

### 解决方案 2：手动配置镜像加速器

```bash
# 创建或编辑 Docker 配置文件
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
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
  ]
}
EOF

# 重启 Docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# 验证配置
docker info | grep -A 10 "Registry Mirrors"
```

### 验证

```bash
# 测试拉取镜像
docker pull python:3.9-slim
docker pull node:18-alpine
```

---

## 2. 端口冲突问题

### 问题症状

```
ERROR: failed to bind host port 0.0.0.0:80/tcp: address already in use
```

### 原因

端口 80、5000 或 3000 已被其他程序占用（通常是系统的 Nginx、Apache 或其他服务）。

### 解决方案 1：使用自动清理脚本（推荐）

```bash
cd deploy
./free-ports.sh
```

脚本会：
- 检查端口 80、5000、3000 的占用情况
- 显示占用进程的详细信息
- 询问是否停止占用进程
- 自动清理端口

### 解决方案 2：手动清理

#### 查找占用端口的进程

```bash
# 查看端口 80
lsof -i:80
# 或
netstat -tlnp | grep :80
# 或
ss -tlnp | grep :80
```

#### 停止占用进程

```bash
# 如果是系统 Nginx
sudo systemctl stop nginx
sudo systemctl disable nginx

# 如果是 Apache
sudo systemctl stop apache2
sudo systemctl disable apache2

# 如果是其他进程，使用 PID 终止
sudo kill -9 <PID>
```

#### 重新启动服务

```bash
cd deploy/docker
docker-compose up -d
```

---

## 3. 前端构建错误

### 问题 A：terser-webpack-plugin 错误

#### 症状

```
SyntaxError: Unexpected end of input
at /app/node_modules/terser-webpack-plugin/dist/index.js:379
```

#### 原因

`terser-webpack-plugin` 在 Docker Alpine Linux 环境中存在兼容性问题，npm 安装时文件可能损坏。

#### 解决方案

已在 `front/webpack.config.js` 中禁用代码压缩：

```javascript
module.exports = {
  mode: 'production',
  optimization: {
    minimize: false  // 禁用压缩
  }
}
```

**权衡：**
- ✅ 100% 构建成功率
- ✅ 构建速度更快
- ✅ 易于调试
- ⚠️ 包体积稍大（1-2MB vs 500KB），但对内网部署影响很小

### 问题 B：ts-loader 错误

#### 症状

```
Module build failed (from ./node_modules/ts-loader/index.js):
/app/node_modules/ts-loader/dist/after-compile.js:67
```

#### 解决方案

已用 Babel 替代 ts-loader：

1. **front/package.json** 添加：
   ```json
   {
     "devDependencies": {
       "@babel/core": "^7.23.0",
       "@babel/preset-env": "^7.23.0",
       "@babel/preset-react": "^7.22.0",
       "@babel/preset-typescript": "^7.23.0",
       "babel-loader": "^9.1.3"
     }
   }
   ```

2. **front/.babelrc** 配置：
   ```json
   {
     "presets": [
       ["@babel/preset-env", { "targets": { "node": "current" } }],
       "@babel/preset-react",
       "@babel/preset-typescript"
     ]
   }
   ```

3. **front/webpack.config.js** 使用 babel-loader：
   ```javascript
   module: {
     rules: [
       {
         test: /\.(ts|tsx)$/,
         use: 'babel-loader',
         exclude: /node_modules/
       }
     ]
   }
   ```

---

## 4. CORS 跨域问题

### 问题症状

```
Access to fetch at 'http://127.0.0.1:5000/api/upload' from origin 'http://8.140.237.35'
has been blocked by CORS policy
```

### 原因

1. **架构问题**：前端直接访问 `127.0.0.1:5000`，而不是通过 Nginx 代理
2. **CORS 配置不足**：Nginx 层面缺少 CORS 响应头

### 解决方案

#### 1. 后端 CORS 配置（已配置）

`api/server.py` 已配置：

```python
CORS(app, resources={
    r"/*": {
        "origins": "*",
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization", "X-Requested-With"],
        "expose_headers": ["Content-Type", "X-Total-Count"],
        "supports_credentials": True
    }
})
```

#### 2. Nginx CORS 配置（已添加）

`deploy/nginx/dimensio.conf` 已添加：

```nginx
location /api/ {
    # CORS 配置
    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization, X-Requested-With' always;

    # 处理 OPTIONS 预检请求
    if ($request_method = 'OPTIONS') {
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
        add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization, X-Requested-With';
        add_header 'Content-Length' 0;
        return 204;
    }

    proxy_pass http://backend:5000;
}
```

#### 3. 验证

```bash
# 重启服务
cd deploy/docker
docker-compose restart

# 测试 CORS
curl -I -X OPTIONS http://your-server-ip/api/compression/history
```

---

## 5. 文件上传大小限制

### 问题症状

```
413 (Request Entity Too Large)
SyntaxError: Unexpected token '<', "<html><h"... is not valid JSON
```

### 原因

1. Flask 服务器限制：原来是 16MB
2. Nginx 限制：原来是 20M
3. 当文件超过限制时，Flask 返回 HTML 错误页面而不是 JSON

### 解决方案

#### 1. 增加 Flask 文件大小限制

`api/server.py` 已修改：

```python
# 从 16MB 增加到 100MB
app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024
```

#### 2. 增加 Nginx 限制

`deploy/nginx/nginx.conf` 已修改：

```nginx
http {
    client_max_body_size 100M;  # 从 20M 增加到 100M
}
```

#### 3. 添加 413 错误处理器

`api/server.py` 已添加：

```python
@app.errorhandler(413)
def request_entity_too_large(error):
    return jsonify({
        'success': False,
        'error': 'File too large. Maximum file size is 100MB.'
    }), 413
```

#### 4. 应用更改

```bash
cd deploy/docker
docker-compose down
docker-compose build
docker-compose up -d
```

---

## 6. Result 目录为空

### 问题症状

用户上传文件后，`/root/dimensio/result` 目录始终为空，压缩任务无法生成结果。

### 错误信息

```
RuntimeError: Compression script failed with exit code 1
OSError: [Errno 16] Device or resource busy: '/app/result'
```

### 原因

**Docker 卷挂载冲突**：`run_compression.py` 尝试删除整个 result 目录，但该目录被 Docker 挂载，无法删除。

### 解决方案

修改 `run_compression.py`，只清理目录内容而不删除目录本身：

```python
# 原代码（有问题）
if self.result_dir.exists():
    shutil.rmtree(self.result_dir)  # 尝试删除整个目录
self.result_dir.mkdir(parents=True, exist_ok=True)

# 修复后代码
if self.result_dir.exists():
    # 只删除目录内容，不删除目录本身
    for item in self.result_dir.iterdir():
        if item.is_file():
            item.unlink()
        elif item.is_dir():
            shutil.rmtree(item)
else:
    self.result_dir.mkdir(parents=True, exist_ok=True)
```

### 验证

```bash
# 重新构建后端
cd deploy/docker
docker-compose build backend
docker-compose up -d backend

# 检查日志
docker-compose logs -f backend

# 上传文件后检查 result 目录
ls -la /root/dimensio/result
```

---

## 7. Debian 镜像源问题

### 问题症状

```
Failed to fetch http://deb.debian.org/debian/dists/bookworm/...
Temporary failure resolving 'deb.debian.org'
```

### 解决方案

在 Dockerfile 中配置国内镜像源：

#### Backend Dockerfile

```dockerfile
FROM python:3.9-slim

# 配置 Debian 镜像源（中国镜像）
RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources && \
    sed -i 's/security.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources
```

#### Frontend Dockerfile

```dockerfile
FROM node:18-alpine

# 配置 Alpine 镜像源（中国镜像）
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
```

---

## 8. 快速诊断脚本

### 诊断后端服务

```bash
cd deploy
./diagnose-backend.sh
```

检查项：
- 容器运行状态
- 端口监听情况
- 后端日志
- 配置文件

### 诊断空结果问题

```bash
cd deploy
./diagnose-empty-results.sh
```

检查项：
- data 目录文件
- result 目录内容
- Docker 容器状态
- 后端错误日志
- 卷挂载情况

### 诊断 Nginx 服务

```bash
cd deploy
./diagnose.sh
```

检查项：
- Nginx 容器状态
- 配置文件语法
- 日志输出
- 网络连接

---

## 常用命令速查

### Docker 相关

```bash
# 查看运行中的容器
docker-compose ps

# 查看日志
docker-compose logs -f [service_name]

# 重启服务
docker-compose restart [service_name]

# 重新构建并启动
docker-compose up -d --build

# 停止所有服务
docker-compose down

# 清理所有（包括卷）
docker-compose down -v
```

### 端口检查

```bash
# 检查端口占用
lsof -i:80
lsof -i:5000
lsof -i:3000

# 查看监听端口
netstat -tlnp | grep LISTEN
ss -tlnp
```

### 日志查看

```bash
# Docker 容器日志
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f nginx

# 系统日志
journalctl -u docker -f
```

### 配置验证

```bash
# Nginx 配置测试
docker exec dimensio-nginx nginx -t

# 查看 Docker 信息
docker info

# 查看镜像加速器配置
docker info | grep -A 10 "Registry Mirrors"
```

---

## 完整部署流程

### 1. 环境准备

```bash
# 安装 Docker 和 Docker Compose
curl -fsSL https://get.docker.com | bash
apt-get install -y docker-compose-plugin

# 配置 Docker 镜像加速器
cd deploy
sudo bash fix-docker-registry.sh
```

### 2. 清理端口冲突

```bash
cd deploy
./free-ports.sh
```

### 3. 配置环境变量

```bash
cd deploy
cp .env.example .env
# 编辑 .env 文件，设置域名或IP
```

### 4. 构建和启动

```bash
cd deploy/docker
docker-compose build
docker-compose up -d
```

### 5. 验证部署

```bash
# 检查容器状态
docker-compose ps

# 检查服务
curl http://localhost
curl http://localhost/api/compression/history

# 查看日志
docker-compose logs -f
```

---

## 故障排查流程图

```
遇到问题
  │
  ├─ 容器无法启动？
  │   ├─ 检查端口冲突 → 运行 free-ports.sh
  │   ├─ 检查镜像拉取 → 配置镜像加速器
  │   └─ 查看容器日志 → docker-compose logs
  │
  ├─ 前端构建失败？
  │   ├─ terser 错误 → 已禁用压缩
  │   ├─ ts-loader 错误 → 已改用 babel
  │   └─ 依赖安装失败 → 配置 npm 镜像
  │
  ├─ API 访问失败？
  │   ├─ CORS 错误 → 检查 Nginx 配置
  │   ├─ 404 错误 → 检查路由配置
  │   └─ 413 错误 → 检查文件大小限制
  │
  └─ 压缩任务失败？
      ├─ result 目录为空 → 检查卷挂载和权限
      ├─ 运行超时 → 增加超时时间
      └─ 依赖缺失 → 检查后端环境
```

---

## 获取帮助

如果以上方案都无法解决问题：

1. **查看详细日志**
   ```bash
   docker-compose logs -f backend > backend.log
   docker-compose logs -f frontend > frontend.log
   docker-compose logs -f nginx > nginx.log
   ```

2. **运行诊断脚本**
   ```bash
   cd deploy
   ./diagnose-backend.sh > diagnose.log
   ./diagnose-empty-results.sh >> diagnose.log
   ```

3. **检查系统信息**
   ```bash
   docker version
   docker-compose version
   cat /etc/os-release
   df -h
   free -h
   ```

4. **提交 Issue**
   - 附上完整的日志文件
   - 说明部署环境（操作系统、Docker 版本等）
   - 描述重现步骤

---

## 版本信息

- **文档版本**: 1.0
- **适用于**: Dimensio Docker 部署
- **最后更新**: 2025-11-23
- **测试环境**: Ubuntu 22.04, Docker 24.x, Docker Compose v2.x
