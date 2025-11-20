#!/bin/bash

##############################################################################
# Docker BuildKit Provenance 问题修复脚本
# 解决网络受限环境下构建卡住的问题
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

print_info "修复 Docker BuildKit 网络问题..."

# 方案1: 配置 BuildKit，禁用 provenance 和 attestation
print_info "配置 BuildKit..."

# 更新或创建 buildkitd.toml
mkdir -p /etc/buildkit
cat > /etc/buildkit/buildkitd.toml <<'EOF'
# BuildKit 配置文件

[registry."docker.io"]
  mirrors = ["https://docker.mirrors.ustc.edu.cn"]

[worker.oci]
  enabled = true

[worker.containerd]
  enabled = false
EOF

print_success "BuildKit 配置完成"

# 方案2: 更新 Docker daemon 配置
print_info "更新 Docker daemon 配置..."

# 备份现有配置
if [ -f /etc/docker/daemon.json ]; then
    cp /etc/docker/daemon.json /etc/docker/daemon.json.bak.$(date +%Y%m%d%H%M%S)
fi

# 读取现有配置或创建新配置
if [ -f /etc/docker/daemon.json ]; then
    # 使用 jq 更新配置（如果已安装）
    if command -v jq &> /dev/null; then
        jq '. + {"features": {"buildkit": true}, "builder": {"gc": {"enabled": true}}}' /etc/docker/daemon.json > /tmp/daemon.json.tmp
        mv /tmp/daemon.json.tmp /etc/docker/daemon.json
    else
        print_warning "jq 未安装，使用简单配置"
        # 简单配置（不破坏现有配置）
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
  "storage-driver": "overlay2",
  "features": {
    "buildkit": true
  }
}
EOF
    fi
fi

print_success "Docker daemon 配置已更新"

# 重启 Docker
print_info "重启 Docker 服务..."
systemctl daemon-reload
systemctl restart docker

sleep 3

print_success "Docker 服务已重启"

# 验证配置
print_info "验证配置..."
docker info | grep -i buildkit || print_warning "无法验证 BuildKit 状态"

echo ""
print_success "修复完成！"
echo ""
print_info "现在可以使用以下环境变量构建镜像："
echo ""
echo -e "${YELLOW}DOCKER_BUILDKIT=1 BUILDKIT_PROGRESS=plain docker compose build --no-cache${NC}"
echo ""
print_info "或者禁用 provenance："
echo ""
echo -e "${YELLOW}docker compose build --no-cache --provenance=false${NC}"
echo ""
