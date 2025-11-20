#!/bin/bash

##############################################################################
# Docker 镜像加速器配置脚本
# 解决 Docker 拉取镜像超时问题
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
    print_error "请使用 root 用户运行此脚本"
    exit 1
fi

print_info "配置 Docker 镜像加速器..."

# 创建 Docker 配置目录
mkdir -p /etc/docker

# 备份原有配置
if [ -f /etc/docker/daemon.json ]; then
    print_warning "备份原有配置文件..."
    cp /etc/docker/daemon.json /etc/docker/daemon.json.bak.$(date +%Y%m%d%H%M%S)
fi

# 创建新的 daemon.json 配置文件
print_info "创建镜像加速器配置..."
cat > /etc/docker/daemon.json <<'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com",
    "https://docker.m.daocloud.io"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

print_success "配置文件已创建"

# 重启 Docker 服务
print_info "重启 Docker 服务..."
systemctl daemon-reload
systemctl restart docker

# 等待 Docker 启动
sleep 3

# 验证配置
print_info "验证配置..."
if docker info | grep -A 10 "Registry Mirrors" | grep -q "http"; then
    print_success "镜像加速器配置成功！"
    echo ""
    echo -e "${GREEN}已配置的镜像源：${NC}"
    docker info | grep -A 10 "Registry Mirrors"
else
    print_warning "无法验证镜像源配置，但配置文件已创建"
fi

echo ""
print_success "Docker 镜像加速器配置完成！"
print_info "现在可以重新执行部署脚本了"
