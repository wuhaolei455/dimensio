# 部署文件清单

## 📁 目录结构

```
deploy/
├── docker/                         # Docker 配置目录
│   ├── Dockerfile.backend          # 后端 Dockerfile (Python 3.9 + Flask)
│   ├── Dockerfile.frontend         # 前端 Dockerfile (Node.js + React + Nginx)
│   └── docker-compose.yml          # Docker Compose 编排文件
│
├── nginx/                          # Nginx 配置目录
│   ├── nginx.conf                  # Nginx 主配置文件
│   ├── dimensio.conf               # 反向代理配置（主服务器）
│   └── default.conf                # 前端服务配置
│
├── .env.example                    # 环境变量示例文件
├── .gitignore                      # Git 忽略文件
├── deploy.sh                       # 一键部署脚本（傻瓜式）⭐
├── manage.sh                       # 服务管理脚本
├── README.md                       # 完整部署文档
├── QUICKSTART.md                   # 快速开始指南
└── FILES.md                        # 本文件清单
```

## 📝 文件说明

### 🐳 Docker 配置

#### Dockerfile.backend
- 基于 Python 3.9 官方镜像
- 安装系统依赖和 Python 包
- 配置 Flask 应用环境
- 监听 5000 端口
- 包含健康检查

#### Dockerfile.frontend
- 多阶段构建
- 第一阶段：使用 Node.js 构建 React 应用
- 第二阶段：使用 Nginx 提供静态文件
- 监听 80 端口

#### docker-compose.yml
- 定义三个服务：backend、frontend、nginx
- 配置服务间网络通信
- 挂载数据卷（data、result、logs）
- 设置自动重启策略

### 🌐 Nginx 配置

#### nginx.conf
- Nginx 主配置文件
- 设置全局参数（worker 进程、连接数等）
- 配置 gzip 压缩
- 设置文件上传大小限制（20MB）

#### dimensio.conf
- 反向代理配置
- 路由规则：
  - `/api/*` → 后端服务 (backend:5000)
  - `/*` → 前端服务 (frontend:80)
  - `/health` → 健康检查
- 设置代理超时（600秒，适应长时间压缩任务）

#### default.conf
- 前端服务配置
- 静态文件服务
- 缓存策略
- SPA 路由支持

### 🛠️ 脚本文件

#### deploy.sh ⭐
**一键部署脚本**（最重要的文件）

功能：
- ✅ 检查系统环境（Root权限、操作系统）
- ✅ 自动安装 Docker 和 Docker Compose
- ✅ 验证项目文件完整性
- ✅ 创建必要的目录
- ✅ 停止旧容器并清理资源
- ✅ 构建 Docker 镜像
- ✅ 启动所有服务
- ✅ 健康检查和验证
- ✅ 配置防火墙
- ✅ 显示访问信息

使用方法：
```bash
cd /root/dimensio/deploy
sudo bash deploy.sh
```

#### manage.sh
**日常管理脚本**

功能：
- `start` - 启动服务
- `stop` - 停止服务
- `restart` - 重启服务
- `status` - 查看状态
- `logs` - 查看日志
- `logs-f` - 实时日志
- `update` - 更新部署
- `rebuild` - 重新构建
- `clean` - 清理资源
- `backup` - 备份数据
- `test` - 测试服务
- `shell` - 进入容器

使用方法：
```bash
cd /root/dimensio/deploy
./manage.sh [命令]
```

### 📄 文档文件

#### README.md
完整的部署文档，包含：
- 系统要求
- 部署架构
- 详细部署步骤
- 常用命令
- 故障排除
- 监控维护

#### QUICKSTART.md
快速开始指南：
- 最简部署步骤
- 快速测试命令
- 常见问题速查

#### .env.example
环境变量模板：
- 服务器配置
- 应用配置
- 端口配置
- Python 版本

## 🚀 使用流程

### 第一次部署

1. 将项目上传到服务器 `/root/dimensio`
2. 执行一键部署脚本：
   ```bash
   cd /root/dimensio/deploy
   sudo bash deploy.sh
   ```
3. 等待部署完成（约 5-10 分钟）
4. 访问 http://8.140.237.35

### 日常维护

使用 `manage.sh` 脚本管理服务：

```bash
cd /root/dimensio/deploy

# 查看状态
./manage.sh status

# 查看日志
./manage.sh logs

# 重启服务
./manage.sh restart

# 更新部署
./manage.sh update

# 备份数据
./manage.sh backup
```

### 代码更新

```bash
cd /root/dimensio/deploy
./manage.sh update
```

或手动：
```bash
cd /root/dimensio
git pull origin main
cd deploy/docker
docker compose up -d --build
```

## 🎯 核心特性

- ✅ **傻瓜式部署**：一个命令完成所有配置
- ✅ **自动化管理**：提供完整的管理脚本
- ✅ **服务隔离**：Docker 容器化部署
- ✅ **反向代理**：Nginx 负载均衡
- ✅ **健康检查**：自动监控服务状态
- ✅ **日志管理**：集中式日志查看
- ✅ **数据持久化**：独立数据卷挂载
- ✅ **快速恢复**：自动重启策略

## 📊 服务端口

| 服务 | 容器端口 | 宿主机端口 | 说明 |
|------|---------|-----------|------|
| Nginx | 80 | 80 | 主入口 |
| Backend | 5000 | 5000 | Flask API |
| Frontend | 80 | 3000 | React 应用 |

## 🔗 访问地址

- 前端应用：http://8.140.237.35
- 后端 API：http://8.140.237.35/api/
- 健康检查：http://8.140.237.35/health

## ⚙️ 配置说明

### 服务器信息
- IP: 8.140.237.35
- 目录: /root/dimensio
- Python: 3.9
- 系统: Ubuntu

### 资源配置
- CPU: 自动使用所有可用核心
- 内存: 无限制（可在 docker-compose.yml 中配置）
- 磁盘: 使用宿主机目录挂载

### 网络配置
- 桥接网络模式
- 服务间内部通信
- 统一对外端口 80

## 🎓 最佳实践

1. **定期备份**：使用 `./manage.sh backup` 备份数据
2. **监控日志**：定期检查 `./manage.sh logs`
3. **及时更新**：保持 Docker 和系统更新
4. **资源监控**：使用 `docker stats` 监控资源
5. **安全加固**：配置 SSL 证书和防火墙

## ❓ 获取帮助

查看完整文档：
```bash
cat /root/dimensio/deploy/README.md
```

查看快速指南：
```bash
cat /root/dimensio/deploy/QUICKSTART.md
```

查看管理命令：
```bash
/root/dimensio/deploy/manage.sh help
```

---

**就是这么简单！一个命令，轻松部署！** 🎉
