# 部署文件清单

## 📁 目录结构

```
deploy/
├── docker/                         # Docker 配置目录
│   ├── Dockerfile.backend          # 后端 Dockerfile (Python 3.9 + Flask)
│   ├── Dockerfile.frontend         # 前端 Dockerfile (Node.js + React)
│   ├── docker-compose.yml          # Docker Compose 编排文件
│   └── build.sh                    # Docker 镜像构建脚本
│
├── nginx/                          # Nginx 配置目录
│   ├── nginx.conf                  # Nginx 主配置文件
│   ├── dimensio.conf               # 反向代理配置（主服务器）
│   ├── default.conf                # 默认服务器配置
│   └── nginx-system.conf           # 系统级 Nginx 配置
│
├── .env.example                    # 环境变量示例文件
├── .gitignore                      # Git 忽略文件
│
├── deploy.sh                       # 🌟 一键部署脚本（推荐）
├── manage.sh                       # 服务管理脚本（启动/停止/重启/状态）
├── fix-docker-registry.sh          # Docker 镜像源配置脚本
├── free-ports.sh                   # 端口冲突清理脚本
├── diagnose-empty-results.sh       # 结果目录诊断脚本
│
├── README.md                       # 📖 完整部署文档
├── QUICKSTART.md                   # 🚀 快速开始指南
├── TROUBLESHOOTING.md              # 🔧 故障排除指南
└── FILES.md                        # 📋 本文件清单
```

## 📝 文件说明

### 🐳 Docker 配置

#### **Dockerfile.backend**
- 后端容器配置
- 基于 `python:3.9-slim`
- 安装 dimensio 依赖
- 暴露端口 5000

#### **Dockerfile.frontend**
- 前端容器配置
- 使用 Node.js 18 Alpine 构建
- 使用 Nginx Alpine 运行
- 暴露端口 80

#### **docker-compose.yml**
- 三服务编排：nginx（反向代理）、backend（API服务）、frontend（前端静态文件）
- 卷挂载：data/、result/ 目录
- 网络配置：dimensio-network

#### **build.sh**
- Docker 镜像构建辅助脚本
- 支持单独构建或全部构建

### 🔧 Nginx 配置

#### **nginx.conf**
- Nginx 主配置文件
- HTTP 全局设置
- GZIP 压缩配置
- 文件上传大小限制（100MB）

#### **dimensio.conf**
- Dimensio 应用配置
- 反向代理到 backend:5000
- CORS 头部配置
- 静态文件服务

#### **default.conf**
- 默认服务器配置
- 处理未匹配的请求

#### **nginx-system.conf**
- 系统级 Nginx 配置参考

### 🚀 部署脚本

#### **deploy.sh** ⭐ 推荐
主部署脚本，自动完成：
1. 系统检查（Docker、Docker Compose）
2. Docker 镜像源配置
3. 端口冲突检测和清理
4. 环境变量配置
5. Docker 镜像构建
6. 容器启动
7. 健康检查

**使用方法：**
```bash
cd deploy
sudo bash deploy.sh
```

#### **manage.sh**
服务管理脚本，支持：
- `start` - 启动服务
- `stop` - 停止服务
- `restart` - 重启服务
- `status` - 查看状态
- `logs` - 查看日志
- `rebuild` - 重新构建

**使用方法：**
```bash
cd deploy
./manage.sh [start|stop|restart|status|logs|rebuild]
```

#### **fix-docker-registry.sh**
Docker 镜像源配置脚本，解决国内访问 Docker Hub 慢的问题。

配置 8 个可靠的中国镜像源：
- docker.1panel.live
- docker.1ms.run
- docker.nju.edu.cn
- docker.mirrors.sjtug.sjtu.edu.cn
- hub.rat.dev
- docker.m.daocloud.io
- dockerproxy.net
- docker.mirrors.ustc.edu.cn

**使用方法：**
```bash
cd deploy
sudo bash fix-docker-registry.sh
```

#### **free-ports.sh**
端口冲突清理脚本，自动处理端口 80、5000、3000 的占用。

功能：
- 检测端口占用
- 显示占用进程详情
- 交互式停止进程
- 支持批量清理

**使用方法：**
```bash
cd deploy
./free-ports.sh
```

#### **diagnose-empty-results.sh**
结果目录诊断脚本，用于排查压缩任务无结果的问题。

检查项：
- data 目录文件
- result 目录内容
- Docker 容器状态
- 后端错误日志
- 卷挂载情况
- 权限问题

**使用方法：**
```bash
cd deploy
./diagnose-empty-results.sh
```

### 📖 文档

#### **README.md**
完整的部署文档，包含：
- 系统要求
- 详细部署步骤
- 配置说明
- 验证测试
- 常见问题

#### **QUICKSTART.md**
快速开始指南，3 步快速部署：
1. 运行 deploy.sh
2. 访问服务
3. 上传测试

#### **TROUBLESHOOTING.md**
故障排除指南，包含：
- Docker 镜像拉取问题
- 端口冲突问题
- 前端构建错误
- CORS 跨域问题
- 文件上传大小限制
- Result 目录为空
- Debian 镜像源问题
- 快速诊断脚本使用

#### **FILES.md**
本文件清单，说明每个文件的用途。

### ⚙️ 配置文件

#### **.env.example**
环境变量模板：
- `SERVER_NAME` - 服务器域名或 IP
- `BACKEND_PORT` - 后端端口（默认 5000）
- `NGINX_PORT` - Nginx 端口（默认 80）

使用方法：
```bash
cp .env.example .env
# 编辑 .env 文件
vim .env
```

## 🎯 快速使用

### 首次部署
```bash
cd deploy
sudo bash deploy.sh
```

### 服务管理
```bash
# 启动服务
./manage.sh start

# 停止服务
./manage.sh stop

# 重启服务
./manage.sh restart

# 查看状态
./manage.sh status

# 查看日志
./manage.sh logs
```

### 故障排查
```bash
# 遇到 Docker 拉取超时
sudo bash fix-docker-registry.sh

# 遇到端口冲突
./free-ports.sh

# 结果目录为空
./diagnose-empty-results.sh

# 查看完整故障排除指南
cat TROUBLESHOOTING.md
```

## 📌 推荐的部署顺序

1. **阅读文档**
   ```bash
   cat QUICKSTART.md
   ```

2. **配置 Docker 镜像源**（如果在中国）
   ```bash
   sudo bash fix-docker-registry.sh
   ```

3. **运行一键部署**
   ```bash
   sudo bash deploy.sh
   ```

4. **验证部署**
   ```bash
   ./manage.sh status
   curl http://localhost
   ```

5. **遇到问题查看故障排除指南**
   ```bash
   cat TROUBLESHOOTING.md
   ```

## 🔗 相关链接

- **项目根目录的 TROUBLESHOOT.md**: 更详细的故障排除指南
- **Docker Hub**: https://hub.docker.com/
- **Docker Compose 文档**: https://docs.docker.com/compose/

## 📝 维护说明

- 定期更新 Docker 镜像: `./manage.sh rebuild`
- 查看日志定位问题: `./manage.sh logs`
- 清理旧数据: `docker-compose down -v`（⚠️ 会删除所有数据）

## ✨ 特性

- ✅ 一键部署，自动化程度高
- ✅ 完善的错误处理和提示
- ✅ 支持中国大陆网络环境
- ✅ 详细的文档和故障排除指南
- ✅ 模块化脚本，易于维护
- ✅ 交互式操作，用户友好
