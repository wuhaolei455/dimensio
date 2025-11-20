#!/bin/bash
###############################################################################
# Docker 镜像源配置脚本
#
# 用法:
#   sudo ./setup-docker-mirror.sh
#
# 说明:
#   配置 Docker daemon 使用国内镜像源，加速镜像拉取
#   适用于中国大陆用户
###############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
    log_error "请使用 sudo 运行此脚本"
    exit 1
fi

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    log_error "Docker 未安装，请先安装 Docker"
    exit 1
fi

log_info "开始配置 Docker 镜像源..."

# 创建 Docker 配置目录
mkdir -p /etc/docker

# 备份现有配置
if [ -f /etc/docker/daemon.json ]; then
    log_info "备份现有配置..."
    cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)
fi

# 生成配置文件
log_info "生成镜像源配置..."

cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": [
    "https://docker.1panel.live",
    "https://docker.1ms.run",
    "https://docker.nju.edu.cn",
    "https://docker.mirrors.sjtug.sjtu.edu.cn",
    "https://hub.rat.dev",
    "https://docker.m.daocloud.io",
    "https://dockerproxy.net",
    "https://docker.mirrors.ustc.edu.cn"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

log_success "配置文件已生成: /etc/docker/daemon.json"

# 重启 Docker 服务
log_info "重启 Docker 服务..."
systemctl daemon-reload
systemctl restart docker

# 等待 Docker 启动
sleep 2

# 验证配置
log_info "验证配置..."
if docker info | grep -A 8 "Registry Mirrors:" > /dev/null; then
    log_success "Docker 镜像源配置成功！"
    echo ""
    docker info | grep -A 8 "Registry Mirrors:"
else
    log_warning "无法验证镜像源配置，请手动检查"
fi

echo ""
log_info "可用的镜像源:"
echo "  1. docker.1panel.live         - 1Panel 镜像（推荐）"
echo "  2. docker.1ms.run             - 毫秒镜像"
echo "  3. docker.nju.edu.cn          - 南京大学"
echo "  4. docker.mirrors.sjtug.sjtu.edu.cn - 上海交通大学"
echo "  5. hub.rat.dev                - Rat 开发镜像"
echo "  6. docker.m.daocloud.io       - DaoCloud"
echo "  7. dockerproxy.net            - Docker 代理"
echo "  8. docker.mirrors.ustc.edu.cn - 中国科技大学"
echo ""
log_success "配置完成！现在可以使用 docker-compose build 构建镜像了"
