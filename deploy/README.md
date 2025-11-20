# Dimensio 服务器部署指南

本指南将帮助你快速部署 Dimensio 项目到生产服务器。

## 目录

- [系统要求](#系统要求)
- [快速开始](#快速开始)
- [详细部署步骤](#详细部署步骤)
- [配置说明](#配置说明)
- [服务管理](#服务管理)
- [故障排查](#故障排查)
- [安全建议](#安全建议)

## 系统要求

### 硬件要求
- **CPU**: 2核或以上
- **内存**: 4GB 或以上
- **磁盘**: 20GB 或以上可用空间

### 操作系统
- Ubuntu 20.04 LTS 或更高版本
- Debian 10 或更高版本
- CentOS 8 或更高版本（需要调整部分命令）

### 软件依赖
- **Python**: 3.7+
- **Node.js**: 14+ 和 npm
- **Nginx**: 1.18+
- **Git**: 任意版本
- **Systemd**: 系统自带

## 快速开始

### 1. 准备服务器

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装基础依赖
sudo apt install -y python3 python3-pip python3-venv \
                    nodejs npm nginx git curl

# 验证安装
python3 --version
node --version
npm --version
nginx -v
```

### 2. 上传项目代码

```bash
# 方法1：使用 Git（推荐）
cd /tmp
git clone https://github.com/Elubrazione/dimensio.git
cd dimensio

# 方法2：使用 rsync 从本地上传
# 在本地执行：
rsync -avz --progress ./dimensio/ user@server-ip:/tmp/dimensio/
```

### 3. 配置环境

```bash
cd /tmp/dimensio/deploy

# 复制环境配置文件
cp .env.example .env

# 编辑配置文件（重要！）
nano .env
```

**必须修改的配置项**：
```bash
# 修改为你的域名或服务器IP
SERVER_NAME=your-domain.com  # 或 192.168.1.100

# 其他配置可以保持默认
DEPLOY_PATH=/var/www/dimensio
PYTHON_CMD=python3
API_PORT=5000
SERVICE_USER=www-data
```

### 4. 一键部署

```bash
# 执行安装（需要 sudo 权限）
sudo ./deploy.sh install
```

安装脚本会自动完成以下操作：
1. ✅ 检查系统依赖
2. ✅ 创建必要的目录
3. ✅ 安装 Python 依赖（虚拟环境）
4. ✅ 构建前端（React + Webpack）
5. ✅ 配置 Nginx 反向代理
6. ✅ 配置 Systemd 服务
7. ✅ 启动所有服务

### 5. 验证部署

```bash
# 查看服务状态
sudo ./deploy.sh status

# 测试 API
curl http://localhost:5000/
curl http://localhost:5000/api/compression/history

# 在浏览器访问
# http://your-domain.com
```

## 详细部署步骤

### 步骤 1: 系统准备

#### 1.1 创建专用用户（可选）

```bash
# 如果不想使用 www-data，可以创建专用用户
sudo useradd -m -s /bin/bash dimensio
sudo usermod -aG sudo dimensio

# 在 .env 中设置
SERVICE_USER=dimensio
SERVICE_GROUP=dimensio
```

#### 1.2 配置防火墙

```bash
# 允许 HTTP 和 HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 允许 SSH（如果需要）
sudo ufw allow 22/tcp

# 启用防火墙
sudo ufw enable
```

### 步骤 2: 配置 SSL/HTTPS（推荐）

#### 2.1 使用 Let's Encrypt（免费）

```bash
# 安装 Certbot
sudo apt install -y certbot python3-certbot-nginx

# 获取证书
sudo certbot --nginx -d your-domain.com

# Certbot 会自动配置 Nginx
```

#### 2.2 使用自己的证书

```bash
# 1. 将证书文件复制到服务器
sudo mkdir -p /etc/ssl/dimensio
sudo cp your-cert.crt /etc/ssl/dimensio/
sudo cp your-key.key /etc/ssl/dimensio/

# 2. 在 .env 中启用 HTTPS
ENABLE_HTTPS=yes
SSL_CERT_PATH=/etc/ssl/dimensio/your-cert.crt
SSL_KEY_PATH=/etc/ssl/dimensio/your-key.key

# 3. 编辑 Nginx 配置文件，启用 HTTPS 部分
sudo nano /etc/nginx/sites-available/dimensio
```

### 步骤 3: 数据库配置（如果需要）

目前项目使用文件存储，如果未来需要数据库：

```bash
# 安装 PostgreSQL（示例）
sudo apt install -y postgresql postgresql-contrib

# 创建数据库和用户
sudo -u postgres psql
CREATE DATABASE dimensio;
CREATE USER dimensio_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE dimensio TO dimensio_user;
\q
```

## 配置说明

### 目录结构

```
/var/www/dimensio/          # 部署根目录
├── api/                    # Flask API
│   ├── server.py          # API 主文件
│   └── requirements.txt   # API 依赖
├── dimensio/              # 核心库
├── front/                 # 前端
│   ├── dist/             # 构建产物
│   └── src/              # 源代码
├── data/                  # 上传的数据文件
├── result/                # 压缩结果
├── venv/                  # Python 虚拟环境
└── run_compression.sh     # 压缩脚本

/var/log/dimensio/         # 日志目录
├── access.log            # API 访问日志
└── error.log             # API 错误日志

/etc/nginx/sites-available/
└── dimensio              # Nginx 配置

/etc/systemd/system/
└── dimensio-api.service  # Systemd 服务配置
```

### 环境变量说明

详见 `.env.example` 文件，主要配置项：

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `DEPLOY_PATH` | 部署路径 | `/var/www/dimensio` |
| `SERVER_NAME` | 域名或IP | `localhost` |
| `API_PORT` | API 端口 | `5000` |
| `API_WORKERS` | Gunicorn Worker 数量 | `4` |
| `API_TIMEOUT` | 请求超时时间（秒） | `600` |
| `LOG_DIR` | 日志目录 | `/var/log/dimensio` |
| `SERVICE_USER` | 运行用户 | `www-data` |

### Nginx 配置调优

编辑 `/etc/nginx/sites-available/dimensio`：

```nginx
# 调整 worker 连接数
upstream dimensio_api {
    server 127.0.0.1:5000;
    keepalive 64;  # 保持连接数
}

# 调整文件上传大小
client_max_body_size 50M;  # 如果需要上传更大的文件

# 添加缓存
location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### Gunicorn 配置调优

编辑 `/etc/systemd/system/dimensio-api.service`：

```ini
# 根据 CPU 核心数调整 worker 数量
# 推荐: (2 × CPU核心数) + 1
ExecStart=/var/www/dimensio/venv/bin/gunicorn \
    --bind 127.0.0.1:5000 \
    --workers 4 \           # 调整这里
    --threads 2 \           # 每个 worker 的线程数
    --timeout 600 \         # 超时时间
    --max-requests 1000 \   # 重启前处理的最大请求数
    --max-requests-jitter 50 \
    api.server:app
```

## 服务管理

### 部署脚本命令

```bash
# 查看所有可用命令
sudo ./deploy.sh

# 常用命令
sudo ./deploy.sh status    # 查看服务状态
sudo ./deploy.sh restart   # 重启服务
sudo ./deploy.sh stop      # 停止服务
sudo ./deploy.sh logs      # 查看日志
sudo ./deploy.sh backup    # 备份数据
sudo ./deploy.sh update    # 更新代码
sudo ./deploy.sh clean     # 清理临时文件
```

### 手动服务管理

```bash
# Systemd 命令
sudo systemctl status dimensio-api    # 查看状态
sudo systemctl start dimensio-api     # 启动
sudo systemctl stop dimensio-api      # 停止
sudo systemctl restart dimensio-api   # 重启
sudo systemctl enable dimensio-api    # 开机自启

# Nginx 命令
sudo systemctl status nginx
sudo systemctl reload nginx           # 重新加载配置
sudo systemctl restart nginx          # 重启
sudo nginx -t                        # 测试配置
```

### 日志查看

```bash
# API 日志
tail -f /var/log/dimensio/access.log
tail -f /var/log/dimensio/error.log

# Systemd 日志
sudo journalctl -u dimensio-api -f        # 实时日志
sudo journalctl -u dimensio-api -n 100    # 最近100行
sudo journalctl -u dimensio-api --since "1 hour ago"

# Nginx 日志
tail -f /var/log/nginx/dimensio_access.log
tail -f /var/log/nginx/dimensio_error.log
```

## 故障排查

### 常见问题

#### 1. 服务无法启动

```bash
# 查看详细错误
sudo journalctl -u dimensio-api -n 50

# 检查端口占用
sudo lsof -i :5000
sudo netstat -tlnp | grep 5000

# 检查权限
ls -la /var/www/dimensio
ls -la /var/log/dimensio
```

#### 2. 前端无法访问

```bash
# 检查 Nginx 配置
sudo nginx -t

# 检查前端文件
ls -la /var/www/dimensio/front/dist

# 查看 Nginx 错误日志
tail -f /var/log/nginx/dimensio_error.log
```

#### 3. API 返回 502 错误

```bash
# 检查 API 服务是否运行
sudo systemctl status dimensio-api

# 检查 Gunicorn 进程
ps aux | grep gunicorn

# 重启 API 服务
sudo systemctl restart dimensio-api
```

#### 4. 文件上传失败

```bash
# 检查目录权限
sudo chown -R www-data:www-data /var/www/dimensio/data
sudo chmod -R 755 /var/www/dimensio/data

# 检查 Nginx 配置
grep client_max_body_size /etc/nginx/sites-available/dimensio

# 检查磁盘空间
df -h
```

#### 5. 压缩任务超时

```bash
# 增加超时时间
# 编辑 /etc/systemd/system/dimensio-api.service
# 修改 --timeout 参数

# 编辑 /etc/nginx/sites-available/dimensio
# 修改 proxy_read_timeout 参数

# 重新加载配置
sudo systemctl daemon-reload
sudo systemctl restart dimensio-api
sudo systemctl reload nginx
```

### 性能优化

#### 1. 增加 Worker 数量

根据服务器性能调整：

```bash
# 编辑服务文件
sudo nano /etc/systemd/system/dimensio-api.service

# 修改 workers 参数
# 公式: (2 × CPU核心数) + 1
--workers 8  # 例如：4核CPU

# 重启服务
sudo systemctl daemon-reload
sudo systemctl restart dimensio-api
```

#### 2. 启用 Gzip 压缩

编辑 Nginx 配置：

```nginx
# 在 /etc/nginx/sites-available/dimensio 中添加
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css text/xml text/javascript
           application/x-javascript application/xml+rss
           application/json application/javascript;
```

#### 3. 配置日志轮转

创建 `/etc/logrotate.d/dimensio`：

```bash
/var/log/dimensio/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data www-data
    sharedscripts
    postrotate
        systemctl reload dimensio-api > /dev/null 2>&1
    endscript
}
```

## 安全建议

### 1. 限制文件上传

```nginx
# 在 Nginx 配置中
location /api/upload {
    client_max_body_size 20M;

    # 限制上传速率
    limit_req zone=upload burst=5;
}
```

### 2. 配置防火墙

```bash
# 只开放必要端口
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw enable
```

### 3. 定期更新

```bash
# 设置自动更新（可选）
sudo apt install unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades

# 手动更新
sudo apt update && sudo apt upgrade -y
```

### 4. 备份策略

```bash
# 使用部署脚本备份
sudo ./deploy.sh backup

# 设置定时备份（crontab）
sudo crontab -e

# 添加每天凌晨2点备份
0 2 * * * cd /var/www/dimensio/deploy && ./deploy.sh backup
```

### 5. 监控告警

推荐使用监控工具：
- **Prometheus + Grafana**: 全面的监控方案
- **Uptime Kuma**: 轻量级的服务监控
- **Netdata**: 实时性能监控

## 更新和维护

### 更新项目代码

```bash
# 使用部署脚本（推荐）
cd /var/www/dimensio/deploy
sudo ./deploy.sh update

# 手动更新
cd /var/www/dimensio
sudo -u www-data git pull
sudo -u www-data source venv/bin/activate
sudo -u www-data pip install -r requirements.txt
cd front && sudo -u www-data npm install && npm run build
sudo systemctl restart dimensio-api
```

### 回滚版本

```bash
# 使用 Git 回滚
cd /var/www/dimensio
git log --oneline  # 查看提交历史
git checkout <commit-hash>
sudo ./deploy.sh update
```

### 清理临时文件

```bash
sudo ./deploy.sh clean

# 或手动清理
cd /var/www/dimensio
find . -type d -name "__pycache__" -exec rm -rf {} +
find . -name "*.pyc" -delete
```

## 生产环境建议

1. **使用 HTTPS**: 务必配置 SSL 证书
2. **启用监控**: 设置服务监控和告警
3. **定期备份**: 至少每天备份一次
4. **资源限制**: 使用 systemd 限制资源使用
5. **日志管理**: 配置日志轮转，避免磁盘占满
6. **安全审计**: 定期检查安全更新和漏洞

## 联系支持

如果遇到问题：
1. 查看 [项目文档](https://github.com/Elubrazione/dimensio)
2. 提交 [Issue](https://github.com/Elubrazione/dimensio/issues)
3. 联系作者: lingchingtung@stu.pku.edu.cn

---

**祝部署成功！** 🎉
