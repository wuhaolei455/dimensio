# Dimensio 部署说明

本项目提供了完整的生产环境部署方案，支持传统部署和 Docker 部署两种方式。

## 📁 部署文件位置

所有部署相关文件位于 `deploy/` 目录：

```
deploy/
├── INDEX.md              # 部署文件索引和导航
├── QUICKSTART.md         # 5分钟快速部署
├── README.md             # 详细部署文档
├── CHECKLIST.md          # 部署检查清单
├── deploy.sh             # 一键部署脚本
├── .env.example          # 环境配置模板
├── nginx/                # Nginx 配置
├── systemd/              # Systemd 服务配置
└── docker/               # Docker 部署方案
```

## 🚀 快速开始

### 方式 1: 传统部署（推荐）

```bash
# 1. 进入部署目录
cd deploy

# 2. 配置环境
cp .env.example .env
nano .env  # 修改 SERVER_NAME

# 3. 一键部署
sudo ./deploy.sh install

# 4. 验证
sudo ./deploy.sh status
```

### 方式 2: Docker 部署

```bash
# 1. 进入 Docker 目录
cd deploy/docker

# 2. 启动服务
docker-compose up -d

# 3. 验证
docker-compose ps
```

## 📖 文档导航

- **新手用户**: 先看 `deploy/QUICKSTART.md`
- **详细配置**: 查看 `deploy/README.md`
- **Docker 部署**: 查看 `deploy/docker/README.md`
- **部署验证**: 使用 `deploy/CHECKLIST.md`
- **完整索引**: 参考 `deploy/INDEX.md`

## 🎯 部署后访问

```bash
# 前端
http://your-domain.com

# API
http://your-domain.com/api/

# 健康检查
http://your-domain.com/health
```

## 🛠️ 常用管理命令

```bash
# 查看状态
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

## ❓ 获取帮助

- 📚 查看 `deploy/INDEX.md` 获取完整文档导航
- 🐛 [提交 Issue](https://github.com/Elubrazione/dimensio/issues)
- 📧 联系: lingchingtung@stu.pku.edu.cn

---

**开始部署**: `cd deploy && cat INDEX.md`
