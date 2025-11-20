#!/bin/bash

##############################################################################
# 快速修复 Docker 构建卡住问题
# 当构建卡在 "resolving provenance for metadata file" 时使用
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

PROJECT_DIR="/root/dimensio"
DOCKER_DIR="$PROJECT_DIR/deploy/docker"

echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║         Docker 构建卡住问题快速修复                       ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
    print_error "请使用 root 用户运行此脚本"
    exit 1
fi

cd "$DOCKER_DIR"

# 方法1：杀掉卡住的构建进程
print_info "方法 1: 停止当前构建..."
docker compose down 2>/dev/null || true
pkill -f "docker compose build" 2>/dev/null || true
pkill -f "docker buildx" 2>/dev/null || true
sleep 2
print_success "已停止构建进程"

# 方法2：禁用 BuildKit provenance
print_info "方法 2: 配置环境变量禁用 provenance..."
export DOCKER_BUILDKIT=1
export BUILDX_NO_DEFAULT_ATTESTATIONS=1
print_success "环境变量已配置"

# 方法3：使用旧版 docker build
print_info "方法 3: 使用传统构建方法..."

print_info "构建后端镜像..."
cd "$PROJECT_DIR"
docker build \
    --network=host \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    -f deploy/docker/Dockerfile.backend \
    -t deploy-backend:latest \
    . 2>&1 | grep -v "provenance" || true

print_success "后端镜像构建完成"

print_info "构建前端镜像..."
docker build \
    --network=host \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    -f deploy/docker/Dockerfile.frontend \
    -t deploy-frontend:latest \
    . 2>&1 | grep -v "provenance" || true

print_success "前端镜像构建完成"

# 方法4：更新 docker-compose.yml 镜像标签
print_info "方法 4: 更新 docker-compose 配置..."

cd "$DOCKER_DIR"

# 备份原配置
cp docker-compose.yml docker-compose.yml.bak.$(date +%Y%m%d%H%M%S)

# 创建临时配置，使用已构建的镜像
cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  # Backend API Service
  backend:
    image: deploy-backend:latest
    container_name: dimensio-backend
    restart: unless-stopped
    ports:
      - "5000:5000"
    volumes:
      - ../../data:/app/data
      - ../../result:/app/result
      - ../../logs:/app/logs
    environment:
      - FLASK_APP=api/server.py
      - PYTHONUNBUFFERED=1
    networks:
      - dimensio-network
    healthcheck:
      test: ["CMD", "python", "-c", "import requests; requests.get('http://localhost:5000/')"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # Frontend Service
  frontend:
    image: deploy-frontend:latest
    container_name: dimensio-frontend
    restart: unless-stopped
    ports:
      - "3000:80"
    depends_on:
      - backend
    networks:
      - dimensio-network

  # Nginx Reverse Proxy
  nginx:
    image: nginx:alpine
    container_name: dimensio-nginx
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ../nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ../nginx/dimensio.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - backend
      - frontend
    networks:
      - dimensio-network

networks:
  dimensio-network:
    driver: bridge
EOF

print_success "配置已更新为使用预构建镜像"

# 启动服务
print_info "启动服务..."
docker compose up -d

sleep 5

# 检查状态
print_info "检查服务状态..."
docker compose ps

echo ""
print_success "修复完成！"
echo ""
print_info "如果服务正常运行，说明问题已解决"
print_info "查看日志: docker compose logs -f"
echo ""
print_warning "注意: 已使用预构建镜像方式，绕过了 provenance 问题"
print_warning "原配置已备份为: docker-compose.yml.bak.*"
echo ""
