#!/bin/bash

##############################################################################
# Dimensio 一键部署脚本
# 适用于 Ubuntu 服务器
# 作者: Auto-generated deployment script
# 版本: 1.0.0
##############################################################################

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
PROJECT_DIR="/root/dimensio"
SERVER_IP="8.140.237.35"

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 打印欢迎信息
print_banner() {
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║         Dimensio 自动部署脚本                             ║"
    echo "║         Docker + Nginx 部署方案                           ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 配置 Docker 镜像加速器
configure_docker_registry() {
    print_info "配置 Docker 镜像加速器..."

    # 创建 Docker 配置目录
    mkdir -p /etc/docker

    # 备份原有配置
    if [ -f /etc/docker/daemon.json ]; then
        if ! grep -q "registry-mirrors" /etc/docker/daemon.json; then
            print_warning "备份原有配置文件..."
            cp /etc/docker/daemon.json /etc/docker/daemon.json.bak.$(date +%Y%m%d%H%M%S)
        else
            print_info "镜像加速器已配置，跳过"
            return 0
        fi
    fi

    # 创建新的 daemon.json 配置文件
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

    print_success "镜像加速器配置完成"

    # 重启 Docker 服务
    print_info "重启 Docker 服务使配置生效..."
    systemctl daemon-reload
    systemctl restart docker
    sleep 3

    print_success "Docker 服务已重启"
}

# 检查项目目录
check_project_dir() {
    print_info "检查项目目录..."

    if [ ! -d "$PROJECT_DIR" ]; then
        print_error "项目目录不存在: $PROJECT_DIR"
        print_info "请确保项目代码已上传到服务器"
        exit 1
    fi

    print_success "项目目录存在: $PROJECT_DIR"

    # 检查必要的文件
    cd "$PROJECT_DIR"

    REQUIRED_FILES=(
        "deploy/docker/Dockerfile.backend"
        "deploy/docker/Dockerfile.frontend"
        "deploy/docker/docker-compose.yml"
        "deploy/nginx/nginx.conf"
        "deploy/nginx/dimensio.conf"
        "requirements.txt"
        "api/server.py"
    )

    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$file" ]; then
            print_error "缺少必要文件: $file"
            exit 1
        fi
    done

    print_success "所有必要文件检查通过"
}

# 创建必要的目录
create_directories() {
    print_info "创建必要的目录..."

    cd "$PROJECT_DIR"
    mkdir -p data result logs
    chmod 755 data result logs

    print_success "目录创建完成"
}

# 停止旧容器
stop_old_containers() {
    print_info "停止旧容器..."

    cd "$PROJECT_DIR/deploy/docker"

    if docker-compose ps | grep -q "Up"; then
        docker-compose down
        print_success "旧容器已停止"
    else
        print_info "没有运行中的容器"
    fi
}

# 清理旧镜像（可选）
clean_old_images() {
    print_info "清理未使用的 Docker 镜像..."
    docker image prune -f
    print_success "镜像清理完成"
}

# 预拉取基础镜像
pre_pull_base_images() {
    print_info "预拉取基础镜像（使用配置的镜像加速器）..."

    # 拉取后端基础镜像
    print_info "拉取 python:3.9-slim..."
    if docker pull python:3.9-slim; then
        print_success "python:3.9-slim 拉取成功"
    else
        print_warning "python:3.9-slim 拉取失败，将在构建时重试"
    fi

    # 拉取前端基础镜像
    print_info "拉取 node:18-alpine..."
    if docker pull node:18-alpine; then
        print_success "node:18-alpine 拉取成功"
    else
        print_warning "node:18-alpine 拉取失败，将在构建时重试"
    fi

    # 拉取 Nginx 镜像
    print_info "拉取 nginx:alpine..."
    if docker pull nginx:alpine; then
        print_success "nginx:alpine 拉取成功"
    else
        print_warning "nginx:alpine 拉取失败，将在构建时重试"
    fi

    print_success "基础镜像预拉取完成"
}

# 构建并启动容器
build_and_start() {
    cd "$PROJECT_DIR/deploy/docker"

    # 预拉取基础镜像，加快构建速度
    pre_pull_base_images

    print_info "构建 Docker 镜像..."

    # 构建镜像（使用 --no-cache 确保完全重建）
    docker-compose build
    print_success "镜像构建完成"

    print_info "启动容器..."
    docker-compose up -d

    print_success "容器启动完成"
}


# 主函数
main() {
    print_banner

    # 执行部署步骤
    configure_docker_registry  # 配置镜像加速器
    check_project_dir
    create_directories
    stop_old_containers
    build_and_start

    print_success "部署完成！"
}

# 运行主函数
main
