# Dimensio 快速部署指南

## 🎯 一分钟快速部署

在 Ubuntu 服务器上执行以下命令即可完成部署：

```bash
# 1. 上传项目到服务器（使用 scp 或其他方式）
# 确保项目位于 /root/dimensio 目录

# 2. 执行一键部署
cd /root/dimensio/deploy
sudo bash deploy.sh
```

就这么简单！脚本会自动完成所有配置。

## ✅ 部署完成后

访问以下地址验证部署：

- **前端应用**: http://8.140.237.35
- **API文档**: http://8.140.237.35/api/
- **健康检查**: http://8.140.237.35/health

## 📁 生成的文件结构

```
/root/dimensio/
├── deploy/
│   ├── docker/
│   │   ├── Dockerfile.backend      # 后端 Docker 配置
│   │   ├── Dockerfile.frontend     # 前端 Docker 配置
│   │   └── docker-compose.yml      # Docker Compose 配置
│   ├── nginx/
│   │   ├── nginx.conf              # Nginx 主配置
│   │   ├── dimensio.conf           # 反向代理配置
│   │   └── default.conf            # 前端配置
│   ├── .env.example                # 环境变量示例
│   ├── deploy.sh                   # 一键部署脚本
│   ├── README.md                   # 完整文档
│   └── QUICKSTART.md              # 本快速指南
├── data/                           # 数据目录
├── result/                         # 结果目录
└── logs/                           # 日志目录
```

## 🔧 常用命令

```bash
cd /root/dimensio/deploy/docker

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 更新代码后重新部署
docker-compose up -d --build
```

## ⚡ 快速测试

```bash
# 测试后端 API
curl http://8.140.237.35/api/

# 测试健康检查
curl http://8.140.237.35/health

# 查看容器状态
docker ps
```

## 🐛 ��到问题？

1. 查看日志: `docker-compose logs -f`
2. 检查容器: `docker-compose ps`
3. 阅读完整文档: `cat /root/dimensio/deploy/README.md`

## 📋 系统要求

- Ubuntu 18.04+ / Debian 10+
- 2核 CPU / 4GB 内存
- 20GB 磁盘空间
- Root 权限
- 开放 80 端口

## 🎉 就是这样！

现在你的 Dimensio 服务已经运行在 http://8.140.237.35 上了！
