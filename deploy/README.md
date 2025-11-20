# Dimensio 部署指南

## 🚀 快速开始

### 一键安装（Ubuntu）

```bash
sudo ./quick-install.sh
```

这一条命令会自动完成所有安装！包括：
- ✅ Python 3.8
- ✅ 系统依赖（git, nginx, nodejs, npm）
- ✅ 配置部署环境
- ✅ 安装 Python 依赖
- ✅ 构建前端
- ✅ 启动服务

---

## 📋 目录

- [快速开始](#-快速开始)
- [脚本说明](#-脚本说明)
- [配置说明](#-配置说明)
- [服务管理](#-服务管理)
- [常见问题](#-常见问题)
- [快速参考](#-快速参考)
- [高级主题](#-高级主题)

---

## 📜 脚本说明

### 核心脚本

#### 1. quick-install.sh - 一键安装脚本 ⭐

**用途**：全新服务器自动安装

```bash
sudo ./quick-install.sh
```

**功能**：
- 自动检测系统
- 安装 Python 3.8（deadsnakes PPA）
- 安装系统依赖
- 创建部署目录
- 配置环境
- 完整部署

**适用场景**：首次部署

---

#### 2. deploy.sh - 核心部署脚本

**完整命令列表**：

```bash
# 全新安装
sudo ./deploy.sh install

# 更新应用（自动备份）
sudo ./deploy.sh update

# 重启服务
sudo ./deploy.sh restart

# 停止服务
sudo ./deploy.sh stop

# 查看状态
sudo ./deploy.sh status

# 查看日志
sudo ./deploy.sh logs

# 备份数据
sudo ./deploy.sh backup

# 清理缓存
sudo ./deploy.sh clean
```

---

#### 3. install-python38.sh - Python 3.8 安装

**用途**：单独安装 Python 3.8

```bash
sudo ./install-python38.sh
```

**安装方式**：
- 选项 1：PPA 安装（推荐，快速）
- 选项 2：源码编译（通用，较慢）

---

## ⚙️ 配置说明

### 环境配置文件

复制并编辑配置：

```bash
cp .env.example .env
nano .env
```

### 主要配置项

```bash
# 部署路径
DEPLOY_PATH=/root/workspace/dimensio

# 服务器域名或 IP
SERVER_NAME=your-domain.com

# Python 命令（必须使用 Python 3.8）
PYTHON_CMD=python3.8

# API 配置
API_PORT=5000                # API 端口
API_WORKERS=4                # Worker 数量（建议等于 CPU 核心数）
API_TIMEOUT=600              # 超时时间（秒）

# 目录配置
LOG_DIR=/var/log/dimensio
DATA_DIR=/root/workspace/dimensio/data
RESULT_DIR=/root/workspace/dimensio/result

# 服务用户
SERVICE_USER=www-data
SERVICE_GROUP=www-data

# 备份配置
BACKUP_DIR=/var/backups/dimensio
BACKUP_KEEP=7                # 保留最近 7 个备份
```

### 修改配置后

```bash
sudo ./deploy.sh restart
```

---

## 🔧 服务管理

### 查看服务状态

```bash
# 使用部署脚本（推荐）
sudo ./deploy.sh status

# 直接使用 systemctl
sudo systemctl status dimensio-api
sudo systemctl status nginx
```

### 管理服务

```bash
# 启动
sudo systemctl start dimensio-api

# 停止
sudo systemctl stop dimensio-api

# 重启
sudo systemctl restart dimensio-api

# 开机自启
sudo systemctl enable dimensio-api
```

### 查看日志

```bash
# 使用部署脚本
sudo ./deploy.sh logs

# 实时日志
sudo journalctl -u dimensio-api -f

# 查看最近 100 行
sudo journalctl -u dimensio-api -n 100 --no-pager

# Nginx 日志
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

---

## ❓ 常见问题

### 1. Python 3.8 未安装

**症状**：
```
python3.8: command not found
```

**解决**：
```bash
sudo ./install-python38.sh
```

或快速安装：
```bash
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.8 python3.8-venv python3.8-dev
```

---

### 2. 服务无法启动

**诊断步骤**：

```bash
# 1. 查看服务状态
sudo systemctl status dimensio-api

# 2. 查看详细日志
sudo journalctl -u dimensio-api -n 50

# 3. 检查端口占用
sudo netstat -tlnp | grep 5000

# 4. 检查虚拟环境
ls -la /root/workspace/dimensio/venv/bin/python
```

**常见原因**：
- 虚拟环境未正确创建 → 删除 venv 目录，重新运行 `deploy.sh install`
- 依赖包安装失败 → 检查日志，手动安装失败的包
- 端口被占用 → 修改 `.env` 中的 `API_PORT`
- 权限问题 → 检查文件所有者是否为 `www-data`

---

### 3. 前端无法访问

**检查清单**：

```bash
# 1. Nginx 状态
sudo systemctl status nginx

# 2. Nginx 配置测试
sudo nginx -t

# 3. 前端是否构建
ls -la /root/workspace/dimensio/front/dist/

# 4. 防火墙
sudo ufw status

# 5. 测试访问
curl http://localhost/
```

**解决方案**：

```bash
# 重新构建前端
cd /root/workspace/dimensio/front
npm install
npm run build

# 重启 Nginx
sudo systemctl restart nginx
```

---

### 4. Gunicorn 未找到

**症状**：
```
gunicorn: command not found
```

**解决**：
```bash
cd /root/workspace/dimensio
source venv/bin/activate
pip install gunicorn
deactivate

sudo systemctl restart dimensio-api
```

---

### 5. 依赖安装失败

**症状**：
```
error: externally-managed-environment
```

**原因**：在系统 Python 环境中使用了 pip，或使用了 sudo pip

**解决**：
```bash
cd /root/workspace/dimensio

# 删除旧环境
rm -rf venv

# 创建新虚拟环境
python3.8 -m venv venv

# 激活虚拟环境
source venv/bin/activate

# 安装依赖（不要用 sudo）
pip install --upgrade pip
pip install -r requirements.txt
pip install -r api/requirements.txt

# 退出虚拟环境
deactivate

# 重启服务
cd deploy
sudo ./deploy.sh restart
```

---

### 6. 权限错误

**症状**：
```
Permission denied: '/root/workspace/dimensio/data'
```

**解决**：
```bash
# 设置正确的所有者
sudo chown -R www-data:www-data /root/workspace/dimensio/data
sudo chown -R www-data:www-data /root/workspace/dimensio/result
sudo chown -R www-data:www-data /var/log/dimensio

# 重启服务
sudo ./deploy.sh restart
```

---

### 7. 端口被占用

**症状**：
```
Address already in use
```

**诊断**：
```bash
# 查看端口占用
sudo netstat -tlnp | grep 5000

# 或使用 lsof
sudo lsof -i :5000
```

**解决方案 1 - 修改端口**：
```bash
nano .env
# 修改 API_PORT=5001
sudo ./deploy.sh restart
```

**解决方案 2 - 杀死占用进程**：
```bash
sudo kill -9 <PID>
sudo ./deploy.sh restart
```

---

## 📚 快速参考

### 常用命令速查

| 操作 | 命令 |
|------|------|
| **安装** | |
| 一键安装 | `sudo ./quick-install.sh` |
| 安装 Python 3.8 | `sudo ./install-python38.sh` |
| 全新部署 | `sudo ./deploy.sh install` |
| **管理** | |
| 查看状态 | `sudo ./deploy.sh status` |
| 重启服务 | `sudo ./deploy.sh restart` |
| 停止服务 | `sudo ./deploy.sh stop` |
| 更新应用 | `sudo ./deploy.sh update` |
| **监控** | |
| 查看日志 | `sudo ./deploy.sh logs` |
| 实时日志 | `sudo journalctl -u dimensio-api -f` |
| API 测试 | `curl http://localhost:5000/` |
| **维护** | |
| 备份数据 | `sudo ./deploy.sh backup` |
| 清理缓存 | `sudo ./deploy.sh clean` |

---

### 重要文件路径

| 文件类型 | 路径 |
|---------|------|
| **配置** | |
| 环境配置 | `/root/workspace/dimensio/deploy/.env` |
| Nginx 配置 | `/etc/nginx/sites-available/dimensio` |
| Systemd 服务 | `/etc/systemd/system/dimensio-api.service` |
| **日志** | |
| 系统日志 | `journalctl -u dimensio-api` |
| Nginx 访问日志 | `/var/log/nginx/access.log` |
| Nginx 错误日志 | `/var/log/nginx/error.log` |
| 应用日志 | `/var/log/dimensio/` |
| **数据** | |
| 数据目录 | `/root/workspace/dimensio/data` |
| 结果目录 | `/root/workspace/dimensio/result` |
| 备份目录 | `/var/backups/dimensio` |
| **代码** | |
| 部署目录 | `/root/workspace/dimensio` |
| 虚拟环境 | `/root/workspace/dimensio/venv` |
| 前端代码 | `/root/workspace/dimensio/front` |
| API 代码 | `/root/workspace/dimensio/api` |

---

### 紧急修复命令

#### 服务崩溃
```bash
sudo systemctl restart dimensio-api
sudo systemctl restart nginx
```

#### 查看错误
```bash
sudo journalctl -u dimensio-api -n 50 --no-pager
```

#### 完全重启
```bash
cd /root/workspace/dimensio/deploy
sudo ./deploy.sh stop
sudo ./deploy.sh start
```

#### 重建虚拟环境
```bash
cd /root/workspace/dimensio
rm -rf venv
python3.8 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pip install -r api/requirements.txt
deactivate
cd deploy
sudo ./deploy.sh restart
```

---

## 🔬 高级主题

### 手动分步安装

如果不使用一键安装，可以分步执行：

#### 步骤 1：安装 Python 3.8

```bash
sudo ./install-python38.sh
```

#### 步骤 2：安装系统依赖

```bash
sudo apt update
sudo apt install -y git nginx curl

# 安装 Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -
sudo apt install -y nodejs
```

#### 步骤 3：配置环境

```bash
cp .env.example .env
nano .env
```

#### 步骤 4：部署应用

```bash
sudo ./deploy.sh install
```

---

### 目录结构

```
/root/workspace/dimensio/
├── api/                    # API 服务端代码
│   ├── server.py          # 主服务文件
│   └── requirements.txt   # API 依赖
├── front/                  # 前端代码
│   ├── src/               # 源代码
│   ├── dist/              # 构建后的文件
│   └── package.json       # 前端依赖
├── data/                   # 数据目录
├── result/                 # 结果目录
├── venv/                   # Python 虚拟环境
├── deploy/                 # 部署脚本
│   ├── quick-install.sh   # 一键安装
│   ├── deploy.sh          # 核心部署脚本
│   ├── install-python38.sh # Python 安装
│   ├── .env.example       # 配置示例
│   ├── .env               # 实际配置
│   ├── nginx/             # Nginx 配置模板
│   ├── systemd/           # Systemd 服务模板
│   └── docker/            # Docker 配置
└── requirements.txt        # Python 依赖
```

---

### 性能优化

#### 调整 Worker 数量

根据 CPU 核心数：

```bash
nano .env

# 设置 worker 数量（推荐 = CPU 核心数）
API_WORKERS=4

sudo ./deploy.sh restart
```

#### 调整超时时间

处理大数据集：

```bash
nano .env

# 增加超时（秒）
API_TIMEOUT=1200

sudo ./deploy.sh restart
```

#### 启用 Gzip 压缩

Nginx 已默认启用，可以调整：

```bash
sudo nano /etc/nginx/sites-available/dimensio

# 添加或修改
gzip on;
gzip_types text/plain text/css application/json application/javascript;
gzip_min_length 1000;

sudo nginx -t
sudo systemctl reload nginx
```

---

### 安全配置

#### 1. 配置防火墙

```bash
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw enable
```

#### 2. 配置 HTTPS（Let's Encrypt）

```bash
# 安装 certbot
sudo apt install certbot python3-certbot-nginx

# 获取证书
sudo certbot --nginx -d your-domain.com

# 自动续期（certbot 会自动配置 cron）
sudo certbot renew --dry-run
```

#### 3. 限制文件上传大小

```bash
# 编辑 Nginx 配置
sudo nano /etc/nginx/sites-available/dimensio

# 添加
client_max_body_size 20M;

# 编辑 .env
nano .env
MAX_UPLOAD_SIZE=20

sudo nginx -t
sudo systemctl reload nginx
sudo ./deploy.sh restart
```

#### 4. 定期备份

```bash
# 添加到 crontab
sudo crontab -e

# 每天凌晨 2 点备份
0 2 * * * cd /root/workspace/dimensio/deploy && ./deploy.sh backup
```

---

### 监控和日志

#### 系统资源监控

```bash
# CPU 和内存
top
htop

# 磁盘使用
df -h
du -sh /root/workspace/dimensio/*

# 服务状态
sudo systemctl status dimensio-api
```

#### 日志轮转配置

```bash
sudo nano /etc/logrotate.d/dimensio

# 添加内容
/var/log/dimensio/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 www-data www-data
}
```

#### 查看日志统计

```bash
# 统计错误数量
sudo journalctl -u dimensio-api | grep -i error | wc -l

# 查看最常见的错误
sudo journalctl -u dimensio-api | grep -i error | sort | uniq -c | sort -nr | head -10
```

---

### 备份和恢复

#### 自动备份

```bash
sudo ./deploy.sh backup
```

备份包含：
- 数据目录
- 结果目录
- 配置文件

备份位置：`/var/backups/dimensio/`

#### 手动恢复

```bash
# 查看备份
ls -lh /var/backups/dimensio/

# 解压备份
cd /var/backups/dimensio
tar -xzf dimensio_backup_20250121_020000.tar.gz

# 恢复数据
sudo cp -r dimensio_backup_20250121_020000/data /root/workspace/dimensio/
sudo cp -r dimensio_backup_20250121_020000/result /root/workspace/dimensio/

# 恢复配置
sudo cp dimensio_backup_20250121_020000/config/.env /root/workspace/dimensio/deploy/

# 重启服务
cd /root/workspace/dimensio/deploy
sudo ./deploy.sh restart
```

---

### 开发和调试

#### 开发模式运行

```bash
cd /root/workspace/dimensio
source venv/bin/activate

# 直接运行 API
cd api
python3.8 server.py

# 或使用 Flask 开发服务器
export FLASK_APP=server.py
export FLASK_ENV=development
flask run --host=0.0.0.0 --port=5000
```

#### 前端开发模式

```bash
cd /root/workspace/dimensio/front
npm run dev
```

#### 调试日志

```bash
# 启用详细日志
nano .env

# 添加
DEBUG=true
LOG_LEVEL=DEBUG

sudo ./deploy.sh restart

# 查看详细日志
sudo journalctl -u dimensio-api -f
```

---

### 卸载

完全卸载 Dimensio：

```bash
# 停止服务
sudo systemctl stop dimensio-api
sudo systemctl disable dimensio-api

# 删除服务文件
sudo rm /etc/systemd/system/dimensio-api.service
sudo systemctl daemon-reload

# 删除 Nginx 配置
sudo rm /etc/nginx/sites-enabled/dimensio
sudo rm /etc/nginx/sites-available/dimensio
sudo systemctl reload nginx

# 删除应用文件
sudo rm -rf /root/workspace/dimensio

# 删除日志和备份（可选）
sudo rm -rf /var/log/dimensio
sudo rm -rf /var/backups/dimensio

# 卸载 Python 3.8（可选）
sudo apt remove python3.8 python3.8-venv python3.8-dev
```

---

## 📞 获取帮助

遇到问题？

1. 查看本 README 的常见问题章节
2. 查看日志：`sudo ./deploy.sh logs`
3. 检查服务状态：`sudo ./deploy.sh status`
4. 提交 Issue 到项目仓库

---

## 📝 更新记录

- **2025-11-21**:
  - 新增 `quick-install.sh` 一键安装脚本
  - 强制使用 Python 3.8
  - 精简部署脚本和文档
  - 优化部署流程

---

**祝使用愉快！** 🎉
