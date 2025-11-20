# Dimensio 部署说明

> **重要更新**: 本项目现已针对 Python 3.8.20 进行优化，确保最佳兼容性和稳定性。

## 📁 部署文件位置

所有部署相关文件位于 `deploy/` 目录。

## 🐍 Python 版本要求

### ⭐ 推荐版本: Python 3.8.20

```bash
✅ 推荐理由:
- 与所有科学计算库完美兼容
- 无 scipy/pythran 编译问题
- 稳定可靠，经过充分测试
```

### 版本兼容性

| Python 版本 | 兼容性 | 推荐度 |
|------------|--------|--------|
| 3.8.x | ⭐⭐⭐⭐⭐ | ✅ 强烈推荐 |
| 3.9.x | ⭐⭐⭐⭐ | ✅ 可以使用 |
| 3.10.x | ⭐⭐⭐ | ⚠️ 谨慎使用 |
| 3.11+ | ⭐⭐ | ❌ 不推荐 (有兼容性问题) |

详见: [Python 版本选择指南](deploy/PYTHON_VERSION_GUIDE.md)

## 🚀 快速开始

### 方案 A: 传统部署（推荐）

```bash
# 1. 安装 Python 3.8
cd deploy
sudo ./install-python38.sh

# 2. 修复依赖
sudo ./fix-deps-py38.sh

# 3. 配置环境
cp .env.example .env
nano .env  # 修改 SERVER_NAME

# 4. 部署
sudo ./deploy.sh install

# 5. 验证
sudo ./deploy.sh status
```

### 方案 B: Docker 部署

```bash
cd deploy/docker
docker-compose up -d
```

## 📚 文档导航

### 核心文档
- **[PYTHON_VERSION_GUIDE.md](deploy/PYTHON_VERSION_GUIDE.md)** - Python 版本选择指南 ⭐ 新增
- **[PYTHON38.md](deploy/PYTHON38.md)** - Python 3.8 使用指南 ⭐ 新增
- **[README.md](deploy/README.md)** - 完整部署文档
- **[QUICKSTART.md](deploy/QUICKSTART.md)** - 5分钟快速部署
- **[TROUBLESHOOTING.md](deploy/TROUBLESHOOTING.md)** - 故障排查文档
- **[INDEX.md](deploy/INDEX.md)** - 文档总索引

### 部署脚本
- **install-python38.sh** - Python 3.8 自动安装脚本 ⭐ 新增
- **fix-deps-py38.sh** - Python 3.8 依赖修复脚本 ⭐ 新增
- **deploy.sh** - 主部署脚本（已更新支持 Python 3.8）
- **fix-scipy-pythran.sh** - Scipy/Pythran 问题修复

### 配置文件
- **.env.example** - 环境变量模板（已更新 Python 配置）
- **nginx/dimensio.conf** - Nginx 配置
- **systemd/dimensio-api.service** - Systemd 服务配置

### Docker 方案
- **docker/Dockerfile** - Docker 镜像（已更新使用 Python 3.8）
- **docker/docker-compose.yml** - Docker Compose 配置
- **docker/README.md** - Docker 部署说明

## 🆕 更新内容

### Python 3.8 支持

1. **新增脚本**:
   - `install-python38.sh` - 一键安装 Python 3.8.20
   - `fix-deps-py38.sh` - 专门为 Python 3.8 优化的依赖安装

2. **更新脚本**:
   - `deploy.sh` - 默认使用 Python 3.8，智能检测版本
   - `fix-scipy-pythran.sh` - 自动适配 Python 版本

3. **更新配置**:
   - `.env.example` - 新增 `PYTHON_CMD` 和 `PYTHON_VERSION` 配置
   - Docker 镜像 - 更新为 `python:3.8-slim`

4. **新增文档**:
   - `PYTHON_VERSION_GUIDE.md` - Python 版本选择完整指南
   - `PYTHON38.md` - Python 3.8 详细使用文档

## 🔄 从旧版本迁移

### 如果你已经部署了旧版本

```bash
# 1. 备份数据
cd /var/www/dimensio/deploy
sudo ./deploy.sh backup

# 2. 安装 Python 3.8
sudo ./install-python38.sh

# 3. 重新创建虚拟环境
sudo ./fix-deps-py38.sh

# 4. 重启服务
sudo ./deploy.sh restart
```

### 如果遇到 scipy 编译问题

```bash
# 使用专门的修复脚本
cd /var/www/dimensio/deploy
sudo ./fix-deps-py38.sh
```

## 💡 常用命令

```bash
cd /var/www/dimensio/deploy

# 查看服务状态
sudo ./deploy.sh status

# 重启服务
sudo ./deploy.sh restart

# 查看日志
sudo ./deploy.sh logs

# 备份数据
sudo ./deploy.sh backup

# 更新代码
sudo ./deploy.sh update
```

## 🎯 部署后访问

```bash
# 前端
http://your-domain.com

# API
http://your-domain.com/api/

# 健康检查
http://your-domain.com/health
```

## 🆘 遇到问题？

### 1. Python 版本问题
查看: [PYTHON_VERSION_GUIDE.md](deploy/PYTHON_VERSION_GUIDE.md)

### 2. Scipy 编译错误
```bash
cd deploy
sudo ./fix-deps-py38.sh
```

### 3. 其他问题
查看: [TROUBLESHOOTING.md](deploy/TROUBLESHOOTING.md)

### 4. 终极方案
使用 Docker:
```bash
cd deploy/docker
docker-compose up -d
```

## 📞 获取帮助

- 📖 查看完整文档: `deploy/INDEX.md`
- 🐛 提交 Issue: https://github.com/Elubrazione/dimensio/issues
- 📧 联系作者: lingchingtung@stu.pku.edu.cn

---

**开始部署**: `cd deploy && cat PYTHON_VERSION_GUIDE.md`

**祝部署顺利！** 🚀
