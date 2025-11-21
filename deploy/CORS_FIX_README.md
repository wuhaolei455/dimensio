# CORS 问题修复指南

## 问题描述

从其他电脑的浏览器访问 `http://8.140.237.35` 时：
- ✅ 前端可以访问
- ❌ 访问后端 API 时出现 CORS 错误
- 错误信息：`Access to fetch at 'http://127.0.0.1:5000/api/upload' from origin 'http://8.140.237.35' has been blocked by CORS policy`

## 根本原因

这个错误有**两个主要原因**：

### 1. **架构问题**（主要原因）
错误信息显示浏览器尝试访问 `http://127.0.0.1:5000/api/upload`，这说明：
- 用户访问的可能是本地开发服务器构建的前端，而不是 Docker 部署的生产版本
- 正确的架构应该是：
  ```
  用户浏览器 → Nginx (80端口) → Backend (5000端口)
                            └→ Frontend (容器内80端口)
  ```

### 2. **CORS 配置不足**
虽然后端已经配置了 CORS，但 Nginx 层面也需要添加 CORS 头部。

## 已实施的修复

### 1. ✅ 后端 CORS 配置（已存在）
文件：`api/server.py`
```python
CORS(app, resources={
    r"/*": {
        "origins": "*",
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization", "X-Requested-With"],
        ...
    }
})
```

### 2. ✅ Nginx CORS 配置（新增）
文件：`deploy/nginx/dimensio.conf`
- 添加了 CORS 响应头
- 正确处理 OPTIONS 预检请求
- 支持跨域访问

### 3. ✅ 前端 API 配置（已正确）
文件：`front/src/services/api.ts`
- 使用相对路径 `/api`（正确做法）
- 会通过 Nginx 反向代理到后端

## 修复步骤

### 快速修复（推荐）

在服务器上执行：

```bash
cd /path/to/dimensio/deploy
./fix-cors-issue.sh
```

这个脚本会：
1. 停止现有容器
2. 重新构建后端和前端镜像
3. 重新启动所有服务
4. 验证 CORS 配置

### 手动修复

如果你想手动执行：

```bash
cd /path/to/dimensio/deploy/docker

# 停止服务
docker-compose down

# 重新构建（无缓存）
docker-compose build --no-cache

# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f
```

## 验证修复

### 1. 检查服务状态

```bash
cd /path/to/dimensio/deploy/docker
docker-compose ps
```

应该看到三个服务都在运行：
- dimensio-nginx
- dimensio-backend
- dimensio-frontend

### 2. 测试 CORS 头部

```bash
# 测试通过 Nginx 访问
curl -I http://localhost/api/compression/history

# 应该看到类似这样的响应头：
# Access-Control-Allow-Origin: *
# Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
```

### 3. 浏览器测试

1. 从其他电脑打开浏览器
2. 访问 `http://8.140.237.35/`
3. 打开开发者工具（F12）→ Network 标签
4. 尝试上传文件或查看历史记录
5. 检查 `/api/upload` 请求：
   - ✅ 状态应该是 200 或 201
   - ✅ 响应头应该包含 `Access-Control-Allow-Origin`
   - ❌ 不应该再看到 CORS 错误

## 常见问题排查

### Q1: 仍然看到 CORS 错误？

**检查是否访问了正确的地址：**
```bash
# 错误：直接访问后端
http://8.140.237.35:5000/api/upload  ❌

# 正确：通过 Nginx 访问
http://8.140.237.35/api/upload  ✅
```

### Q2: 请求到 `http://127.0.0.1:5000`？

这说明你可能在运行本地开发服务器。请：

1. 停止本地 webpack-dev-server
2. 确保通过 Docker 访问生产构建
3. 不要使用 `npm run dev` 或 `npm start`

### Q3: Nginx 返回 502 Bad Gateway？

后端可能没有正常启动：

```bash
# 查看后端日志
cd /path/to/dimensio/deploy/docker
docker-compose logs backend

# 重启后端
docker-compose restart backend
```

### Q4: 前端显示空白页面？

前端可能没有正确构建：

```bash
# 重新构建前端
cd /path/to/dimensio/deploy/docker
docker-compose build frontend --no-cache
docker-compose restart frontend
```

## 架构说明

正确的部署架构：

```
Internet
    ↓
http://8.140.237.35:80 (Nginx)
    ↓
    ├── /api/*  →  http://backend:5000 (Flask API)
    └── /*      →  http://frontend:80 (React SPA)
```

关键点：
- ✅ 所有访问都通过 Nginx (80端口)
- ✅ 前端使用相对路径 `/api` 请求后端
- ✅ Nginx 反向代理到对应服务
- ✅ CORS 头由 Nginx 和后端共同处理
- ❌ 不直接暴露后端 5000 端口

## 相关文件

修改的文件：
- `deploy/nginx/dimensio.conf` - 添加了 CORS 配置
- `deploy/fix-cors-issue.sh` - 修复脚本（新建）

无需修改的文件（已正确）：
- `api/server.py` - 后端 CORS 已配置
- `front/src/services/api.ts` - 前端使用相对路径

## 开发 vs 生产

### 开发环境（本地）
```bash
# 前端开发服务器（webpack-dev-server）
cd front
npm run dev  # http://localhost:3000

# webpack 会代理 /api 到 http://127.0.0.1:5000
```

### 生产环境（服务器）
```bash
# Docker Compose 部署
cd deploy/docker
docker-compose up -d

# 通过 Nginx 访问：http://8.140.237.35/
```

**重要：生产环境不应该使用 webpack-dev-server！**

## 总结

修复包括：
1. ✅ 在 Nginx 配置中添加 CORS 头部支持
2. ✅ 正确处理 OPTIONS 预检请求
3. ✅ 确保通过 Docker 部署，而不是本地开发服务器
4. ✅ 提供自动化修复脚本

如果问题仍然存在，请检查：
- 是否通过 80 端口（Nginx）访问，而不是 5000 端口
- 是否停止了本地开发服务器
- 浏览器开发者工具中请求的实际 URL 是什么
