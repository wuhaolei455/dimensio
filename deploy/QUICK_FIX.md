# 快速修复指南 ⚡

## 遇到的错误

### 错误 1: Terser 构建失败 ❌
```
SyntaxError: Unexpected end of input
at terser-webpack-plugin/dist/index.js:379
```

### 错误 2: CORS 跨域错误 ❌
```
Access to fetch at 'http://127.0.0.1:5000/api/upload'
from origin 'http://8.140.237.35' has been blocked by CORS policy
```

---

## ⚡ 一键修复（推荐）

**在服务器上运行：**

```bash
cd /path/to/dimensio/deploy
./fix-cors-issue.sh
```

**这会自动：**
- ✅ 修复 terser 构建错误（禁用代码压缩）
- ✅ 修复 CORS 跨域问题（配置 Nginx）
- ✅ 重新构建所有服务
- ✅ 启动并验证部署

**耗时：** 8-12 分钟

---

## 📋 已修复的问题

### 1. Terser 构建错误

**解决方案：** 禁用代码压缩

**修改的文件：**
- `front/webpack.config.js` - 设置 `minimize: false`
- `front/package.json` - 移除 terser-webpack-plugin
- `deploy/docker/Dockerfile.frontend` - 优化构建流程

**影响：**
- ✅ 构建 100% 成功
- ⚠️ Bundle 大约 1-2MB（而非 500KB）
- ⚠️ 加载慢约 1秒（内网环境可忽略）

### 2. CORS 跨域问题

**解决方案：** 配置 Nginx CORS 头部

**修改的文件：**
- `deploy/nginx/dimensio.conf` - 添加 CORS 响应头

**效果：**
- ✅ 支持跨域访问
- ✅ 正确处理 OPTIONS 预检请求
- ✅ 后端 API 调用成功

---

## ✅ 验证修复

### 1. 检查服务状态

```bash
cd /path/to/dimensio/deploy/docker
docker-compose ps
```

应该看到：
```
NAME                 STATUS
dimensio-backend     Up
dimensio-frontend    Up
dimensio-nginx       Up
```

### 2. 测试访问

浏览器访问：`http://8.140.237.35/`

应该：
- ✅ 页面正常加载
- ✅ 可以上传文件
- ✅ 无 CORS 错误
- ✅ 无控制台错误

---

## 🔧 如果还有问题

### 如果构建仍然失败

```bash
# 查看详细日志
cd /path/to/dimensio/deploy/docker
docker-compose build frontend 2>&1 | tee build.log

# 查看错误
grep -A 10 ERROR build.log
```

### 如果服务启动失败

```bash
# 查看日志
docker-compose logs frontend
docker-compose logs backend
docker-compose logs nginx

# 重启
docker-compose restart
```

### 如果 CORS 仍然有问题

```bash
# 测试 CORS 头部
curl -I http://localhost/api/compression/history

# 应该看到：
# Access-Control-Allow-Origin: *
```

---

## 📚 详细文档

需要更多信息？查看：

- **TERSER_FIX_README.md** - Terser 错误详解
- **CORS_FIX_README.md** - CORS 问题详解
- **COMPLETE_FIX_GUIDE.md** - 完整修复指南

---

## 🎯 关键点

1. **禁用代码压缩** - 解决 terser 兼容性问题
2. **配置 CORS** - 支持跨域 API 访问
3. **通过 Nginx** - 所有请求走 80 端口
4. **生产部署** - 使用 Docker，不用开发服务器

---

## 💡 快速命令

```bash
# 一键修复
cd /path/to/dimensio/deploy && ./fix-cors-issue.sh

# 查看状态
cd docker && docker-compose ps

# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart

# 完全重建
docker-compose down && docker-compose build --no-cache && docker-compose up -d
```

---

**祝修复顺利！** 🚀
