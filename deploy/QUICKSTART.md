# Dimensio 快速部署指南

> 5分钟快速部署到生产服务器

## 前提条件

- Ubuntu 20.04+ 或 Debian 10+ 服务器
- 拥有 sudo 权限
- 已配置 SSH 访问

## 一键部署（推荐）

### 1. 在服务器上执行

```bash
# 安装基础依赖
sudo apt update && sudo apt install -y python3 python3-pip python3-venv \
                                       nodejs npm nginx git curl

# 克隆项目（或使用 rsync 上传）
cd /tmp
git clone https://github.com/Elubrazione/dimensio.git
cd dimensio/deploy

# 配置环境
cp .env.example .env
nano .env  # 修改 SERVER_NAME 为你的域名或IP

# 执行一键部署
sudo ./deploy.sh install
```

### 2. 验证部署

```bash
# 查看服务状态
sudo ./deploy.sh status

# 测试 API
curl http://localhost:5000/

# 浏览器访问
# http://your-domain.com
```

## 配置要点

### 必须修改的配置（.env 文件）

```bash
# 域名或IP地址（重要！）
SERVER_NAME=your-domain.com  # 或 192.168.1.100

# 其他可选配置
DEPLOY_PATH=/var/www/dimensio     # 部署路径
API_PORT=5000                     # API 端口
API_WORKERS=4                     # Worker 数量
SERVICE_USER=www-data             # 运行用户
```

## 常用命令

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

## 目录结构

```
/var/www/dimensio/          # 部署目录
├── api/                    # Flask API
├── front/dist/            # 前端构建产物
├── data/                  # 上传的数据
├── result/                # 压缩结果
└── venv/                  # Python 虚拟环境

/var/log/dimensio/         # 日志目录
/var/backups/dimensio/     # 备份目录
```

## 端口说明

- **5000**: Flask API（内部端口，通过 Nginx 代理）
- **80**: HTTP（Nginx 对外端口）
- **443**: HTTPS（可选，需要配置 SSL）

## 防火墙配置

```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS（可选）
sudo ufw enable
```

## 配置 HTTPS（可选）

### 使用 Let's Encrypt（免费）

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

Certbot 会自动配置 Nginx HTTPS。

## 常见问题

### 1. 服务启动失败

```bash
# 查看详细错误
sudo journalctl -u dimensio-api -n 50

# 检查权限
sudo chown -R www-data:www-data /var/www/dimensio
```

### 2. 前端无法访问

```bash
# 检查 Nginx 配置
sudo nginx -t

# 检查前端文件
ls -la /var/www/dimensio/front/dist
```

### 3. 文件上传失败

```bash
# 设置正确的权限
sudo chown -R www-data:www-data /var/www/dimensio/data
sudo chmod -R 755 /var/www/dimensio/data
```

## 性能调优

根据服务器配置调整 Worker 数量：

```bash
# 编辑 .env 文件
API_WORKERS=8  # 推荐: (2 × CPU核心数) + 1

# 重新部署
sudo ./deploy.sh restart
```

## 备份和恢复

```bash
# 创建备份
sudo ./deploy.sh backup

# 备份文件位置
ls -lh /var/backups/dimensio/

# 恢复（手动）
cd /var/backups/dimensio/
tar -xzf dimensio_backup_YYYYMMDD_HHMMSS.tar.gz
# 然后手动恢复文件到对应目录
```

## 监控日志

```bash
# 实时查看 API 日志
tail -f /var/log/dimensio/access.log
tail -f /var/log/dimensio/error.log

# 实时查看 Systemd 日志
sudo journalctl -u dimensio-api -f
```

## 更新项目

```bash
cd /var/www/dimensio/deploy
sudo ./deploy.sh update
```

更新脚本会自动：
1. 备份当前数据
2. 停止服务
3. 更新代码
4. 重新安装依赖
5. 重新构建前端
6. 重启服务

## 完全卸载

```bash
# 停止服务
sudo systemctl stop dimensio-api
sudo systemctl disable dimensio-api

# 删除文件
sudo rm -rf /var/www/dimensio
sudo rm -rf /var/log/dimensio
sudo rm /etc/nginx/sites-enabled/dimensio
sudo rm /etc/nginx/sites-available/dimensio
sudo rm /etc/systemd/system/dimensio-api.service

# 重新加载配置
sudo systemctl daemon-reload
sudo systemctl reload nginx
```

## 获取帮助

- 📖 [详细部署文档](./README.md)
- 🐛 [提交 Issue](https://github.com/Elubrazione/dimensio/issues)
- 📧 联系作者: lingchingtung@stu.pku.edu.cn

---

**祝部署成功！** 🚀
