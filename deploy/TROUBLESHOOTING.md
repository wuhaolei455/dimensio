# Dimensio 部署故障排除指南

本指南整理了在部署过程中遇到的所有问题及其解决方案。

---

## 📋 本次部署解决的核心问题

### ⚠️ 问题 1: Result 目录为空（最关键）

**提交**: `fix: no res` (d4846d5, 7d6c52c)

**症状：**
```
OSError: [Errno 16] Device or resource busy: '/app/result'
RuntimeError: Compression script failed with exit code 1
```

**根本原因：**
`run_compression.py` 尝试删除 Docker 卷挂载点目录 `/app/result`，导致：
- `shutil.rmtree(self.result_dir)` 失败
- 压缩脚本无法初始化
- 结果目录始终为空

**解决方案：**
修改 `run_compression.py`，只清空目录内容，不删除目录本身：
```python
# 修复前 - 失败
shutil.rmtree(self.result_dir)  # 尝试删除挂载点

# 修复后 - 成功
for item in self.result_dir.iterdir():
    if item.is_file():
        item.unlink()
    elif item.is_dir():
        shutil.rmtree(item)
```

**验证：**
```bash
# 重新构建后端
cd /root/dimensio/deploy/docker
docker-compose build backend
docker-compose up -d backend

# 测试上传
curl -X POST http://localhost:5000/api/upload \
  -F 'config_space=@config_space.json' \
  -F 'steps=@steps.json' \
  -F 'history=@history.json'
```

**相关文档：** `FIXED_EMPTY_RESULT_ISSUE.md`

---

### ⚠️ 问题 2: CORS 跨域访问错误

**提交**: `fix: cors` (23ee725, d92491d)

**症状：**
```
Access to fetch at 'http://127.0.0.1:5000/api/upload' from origin
'http://8.140.237.35' has been blocked by CORS policy
```

**根本原因：**
1. Nginx 反向代理层缺少 CORS 头部
2. 前端直接访问 localhost:5000（架构问题）
3. OPTIONS 预检请求未正确处理

**解决方案：**

1. 在 `nginx/dimensio.conf` 添加 CORS 头部：
```nginx
location /api/ {
    # CORS headers
    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization' always;

    # Handle OPTIONS requests
    if ($request_method = 'OPTIONS') {
        return 204;
    }

    proxy_pass http://backend;
}
```

2. 前端使用相对路径 `/api` 而不是 `http://localhost:5000`

**验证：**
```bash
# 测试 CORS
curl -H "Origin: http://example.com" \
     -H "Access-Control-Request-Method: POST" \
     -X OPTIONS http://8.140.237.35/api/upload -v
```

**相关文档：** `CORS_FIX_README.md`

---

### ⚠️ 问题 3: 前端构建失败 - Terser 错误

**提交**: `fix: front` (7cd37c7), `fix: front production build` (7280f0d), `fix: front build` (578ccc7)

**症状：**
```
SyntaxError: Unexpected end of input
at /app/node_modules/terser-webpack-plugin/dist/index.js:379
```

**根本原因：**
`terser-webpack-plugin` 在 Alpine Linux Docker 环境中存在兼容性问题：
- npm 安装时文件可能损坏
- Node.js 与 Alpine 的兼容性问题

**解决方案 1 - 禁用压缩（最终采用）：**

修改 `front/webpack.config.js`：
```javascript
optimization: {
  minimize: false,  // 禁用代码压缩
}
```

修改 `front/package.json`：
```json
{
  "devDependencies": {
    // 移除 terser-webpack-plugin
  }
}
```

**权衡：**
- ✅ 100% 构建成功
- ✅ 构建速度更快
- ⚠️ 包体积增加 2-3 倍（但内网可接受）

**解决方案 2 - 切换到 Babel（备选）：**
```javascript
// 用 babel-loader 替换 ts-loader
module: {
  rules: [
    {
      test: /\.(ts|tsx)$/,
      use: 'babel-loader'
    }
  ]
}
```

**验证：**
```bash
# 本地测试构建
cd front
npm run build

# Docker 构建
cd deploy/docker
docker-compose build frontend
```

**相关文档：** `TERSER_FIX_README.md`, `README_WORKING_BUILD.md`

---

### ⚠️ 问题 4: 端口 80 被占用

**提交**: `fix: push` (460302d)

**症状：**
```
ERROR: failed to bind host port 0.0.0.0:80/tcp: address already in use
```

**根本原因：**
系统 Nginx 或 Apache 占用了 80 端口

**解决方案：**

**方法 1 - 使用自动脚本（推荐）：**
```bash
cd /root/dimensio/deploy
./free-ports.sh
```

**方法 2 - 手动清理：**
```bash
# 查找占用进程
lsof -i:80

# 停止系统 Nginx
systemctl stop nginx
systemctl disable nginx

# 或停止 Apache
systemctl stop apache2
systemctl disable apache2

# 验证端口已释放
lsof -i:80
```

**验证：**
```bash
# 启动服务
cd /root/dimensio/deploy/docker
docker-compose up -d
```

**相关文档：** `FIX_PORT_CONFLICT.md`

---

### ⚠️ 问题 5: TypeScript 编译错误 - ts-loader

**提交**: `fix: backend` (e0fa286), `fix: server load` (1796893)

**症状：**
```
Module build failed (from ./node_modules/ts-loader/index.js)
Error: Cannot find module './webpack-cli'
```

**根本原因：**
服务器系统全局安装的 Node.js 与项目依赖冲突

**解决方案：**

**方法 1 - 切换到 Babel（推荐）：**

创建 `front/.babelrc`：
```json
{
  "presets": [
    "@babel/preset-env",
    "@babel/preset-react",
    "@babel/preset-typescript"
  ]
}
```

修改 `package.json`：
```json
{
  "devDependencies": {
    "@babel/core": "^7.23.6",
    "@babel/preset-env": "^7.23.6",
    "@babel/preset-typescript": "^7.23.3",
    "babel-loader": "^9.1.3"
    // 移除 ts-loader
  }
}
```

**方法 2 - 使用 npx 强制本地版本：**
```bash
npx webpack --config webpack.config.js
```

**验证：**
```bash
cd front
npm install
npm run build
```

**相关文档：** `MANUAL_BUILD_TEST.md`

---

### ⚠️ 问题 6: Docker 镜像拉取超时

**提交**: `fix: nginx` (067203e), `fix: debain mirror` (4c422a8), `fix: docker registry` (fe84c4a)

**症状：**
```
ERROR [backend internal] load metadata for docker.io/library/python:3.9-slim
dial tcp 198.44.185.131:443: i/o timeout
```

**根本原因：**
国内服务器访问 Docker Hub 和 Debian 官方源速度慢或超时

**解决方案：**

**Docker 镜像加速：**
```bash
# 使用自动脚本
cd /root/dimensio/deploy
./fix-docker-registry.sh

# 或手动配置 /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ]
}
```

**Debian 软件源加速：**
在 `Dockerfile.backend` 中：
```dockerfile
RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources
```

**npm 加速：**
在 `Dockerfile.frontend` 中：
```dockerfile
RUN npm config set registry https://registry.npmmirror.com
```

**验证：**
```bash
# 测试 Docker 镜像拉取
docker pull python:3.9-slim

# 检查配置
docker info | grep -A 10 "Registry Mirrors"
```

**相关文档：** `DOCKER_MIRROR_SETUP.md`

---

## 📊 完整提交历史 (9f45a6e..fbb56c4)

本次部署共解决了 28 个提交中的问题，最终合并为 1 个综合提交：

| 提交 | 问题分类 | 描述 |
|------|---------|------|
| d4846d5, 7d6c52c | 🔴 后端错误 | 修复 result 目录为空 - Docker 卷挂载冲突 |
| 1796893 | 🟡 构建错误 | 修复服务器端加载错误 - ts-loader 与系统 Node.js 冲突 |
| 3a47585 | 🟢 通用修复 | 通用问题修复 |
| 5f3a90b | 📝 日志改进 | 添加错误日志记录 |
| cf1fb33, 7cd37c7 | 🔴 前端错误 | 修复前端构建 - terser 和 ts-loader 问题 |
| 9911fe1 | 🟢 通用修复 | 通用问题修复 |
| 578ccc7 | 🔴 前端错误 | 修复前端构建错误 |
| 7280f0d | 🔴 前端错误 | 修复前端生产构建 |
| d92491d, 23ee725 | 🔵 CORS | 修复 CORS 跨域访问问题 |
| ca6b573 | 🟢 通用修复 | 通用问题修复 |
| e0fa286 | 🔴 后端错误 | 修复后端配置 |
| 460302d | 🟡 部署 | 修复推送部署问题 - 端口冲突 |
| 067203e, 0bf1520 | 🔵 Nginx | 修复 Nginx 配置错误 |
| 4c422a8 | 🟡 镜像源 | 修复 Debian 镜像源 |
| 9a33b9d | 🟢 Docker Compose | 使用 docker-compose |
| e5f96da | 🟢 通用修复 | 通用问题修复 |
| 9cce0ec | 🟢 元数据 | 跳过元数据检查 |
| c55abee | 🟢 通用修复 | 通用问题修复 |
| fe84c4a | 🟡 镜像源 | 修复 Docker registry |
| d33d39b | 🟢 Docker | 添加 Docker 部署 |
| 5cb0565 | 🔴 清理 | 删除旧部署文件 |
| 1fccf08 | 🟢 通用修复 | 通用问题修复 |
| cb20aad | 🟢 通用修复 | 通用问题修复 |
| 64f0938 | 🟡 部署 | 修复部署脚本 |

### 问题统计

- 🔴 **前端/后端错误**: 8 个提交
- 🔵 **CORS/Nginx 配置**: 4 个提交
- 🟡 **部署/镜像源**: 5 个提交
- 🟢 **通用/优化**: 11 个提交

### 核心改进

1. **架构优化**
   - 3 层 Docker Compose 架构（nginx + frontend + backend）
   - 正确的卷挂载和目录管理
   - 健康检查和依赖管理

2. **构建系统**
   - 从 ts-loader 切换到 babel-loader
   - 禁用 terser 压缩避免 Alpine 兼容性问题
   - 详细的构建日志和错误处理

3. **网络配置**
   - 完整的 CORS 支持（Flask + Nginx）
   - 正确的反向代理配置
   - 长时间运行任务的超时配置

4. **中国网络优化**
   - Docker Hub 镜像加速
   - Debian/Ubuntu APT 源替换
   - npm 镜像源配置

5. **诊断工具**
   - `diagnose-empty-results.sh` - 结果目录诊断
   - `free-ports.sh` - 端口冲突自动清理
   - `fix-docker-registry.sh` - Docker 镜像源配置
   - 各种专项修复脚本

---

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
docker-compose up -d
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
docker-compose logs backend
docker-compose logs frontend
docker-compose logs nginx

# 重新构建容器
docker-compose down
docker-compose up -d --build --force-recreate

# 查看详细错误
docker-compose up
```

### 6. 前端无法连接后端

**症状：**
前端页面能访问，但 API 请求失败

**解决方案：**
```bash
# 检查网络连通性
docker-compose exec frontend ping backend

# 检查 Nginx 配置
docker-compose exec nginx cat /etc/nginx/conf.d/default.conf
docker-compose exec nginx nginx -t

# 重启 Nginx
docker-compose restart nginx

# 查看 Nginx 日志
docker-compose logs nginx
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
docker-compose build --no-cache backend
docker-compose up -d
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
docker-compose build --no-cache frontend
docker-compose up -d
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
docker-compose version

# Docker 资源使用
docker stats

# Docker 磁盘使用
docker system df
```

### 检查容器状态
```bash
cd /root/dimensio/deploy/docker

# 容器状态
docker-compose ps

# 所有容器（包括停止的）
docker-compose ps -a

# 容器日志
docker-compose logs -f

# 特定容器日志
docker-compose logs -f backend
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
docker-compose version
docker info

echo -e "\n===== 容器状态 ====="
cd /root/dimensio/deploy/docker
docker-compose ps -a

echo -e "\n===== 最近日志 ====="
docker-compose logs --tail=50

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
docker-compose down -v

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
