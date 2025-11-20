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

# 检查是否为 root 用户
check_root() {
    print_info "检查用户权限..."
    if [ "$EUID" -ne 0 ]; then
        print_error "请使用 root 用户运行此脚本"
        print_info "使用命令: sudo bash deploy.sh"
        exit 1
    fi
    print_success "用户权限检查通过"
}

# 检查操作系统
check_os() {
    print_info "检查操作系统..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
        print_success "操作系统: $OS $VERSION"
    else
        print_error "无法识别操作系统"
        exit 1
    fi
}

# 更新系统
update_system() {
    print_info "更新系统包..."
    apt-get update -y
    apt-get upgrade -y
    print_success "系统更新完成"
}

# 安装 Docker
install_docker() {
    print_info "检查 Docker 是否已安装..."

    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        print_success "Docker 已安装: $DOCKER_VERSION"
        return 0
    fi

    print_info "开始安装 Docker..."

    # 安装依赖包
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # 添加 Docker 官方 GPG key
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # 设置 Docker 仓库
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 安装 Docker Engine
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # 启动 Docker
    systemctl start docker
    systemctl enable docker

    DOCKER_VERSION=$(docker --version)
    print_success "Docker 安装完成: $DOCKER_VERSION"
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

# 安装 Docker Compose
install_docker_compose() {
    print_info "检查 Docker Compose 是否已安装..."

    if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
        if docker compose version &> /dev/null; then
            COMPOSE_VERSION=$(docker compose version)
        else
            COMPOSE_VERSION=$(docker-compose --version)
        fi
        print_success "Docker Compose 已安装: $COMPOSE_VERSION"
        return 0
    fi

    print_info "Docker Compose 已作为 Docker 插件安装"
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

    if docker compose ps | grep -q "Up"; then
        docker compose down
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

# 构建并启动容器
build_and_start() {
    print_info "构建 Docker 镜像..."

    cd "$PROJECT_DIR/deploy/docker"

    # 构建镜像
    docker compose build --no-cache
    print_success "镜像构建完成"

    print_info "启动容器..."
    docker compose up -d

    print_success "容器启动完成"
}

# 检查容器状态
check_containers() {
    print_info "检查容器状态..."

    sleep 5  # 等待容器启动

    cd "$PROJECT_DIR/deploy/docker"

    echo ""
    docker compose ps
    echo ""

    # 检查每个服务
    SERVICES=("backend" "frontend" "nginx")
    ALL_RUNNING=true

    for service in "${SERVICES[@]}"; do
        if docker compose ps | grep "dimensio-$service" | grep -q "Up"; then
            print_success "$service 服务运行正常"
        else
            print_error "$service 服务未运行"
            ALL_RUNNING=false
        fi
    done

    if [ "$ALL_RUNNING" = true ]; then
        print_success "所有服务运行正常"
    else
        print_error "部分服务未正常运行，请检查日志"
        print_info "查看日志命令: cd $PROJECT_DIR/deploy/docker && docker compose logs"
        return 1
    fi
}

# 测试服务
test_services() {
    print_info "测试服务连接..."

    sleep 5  # 等待服务完全启动

    # 测试后端 API
    print_info "测试后端 API..."
    if curl -f http://localhost:5000/ > /dev/null 2>&1; then
        print_success "后端 API 响应正常"
    else
        print_warning "后端 API 可能未完全启动，请稍后检查"
    fi

    # 测试 Nginx
    print_info "测试 Nginx..."
    if curl -f http://localhost/health > /dev/null 2>&1; then
        print_success "Nginx 响应正常"
    else
        print_warning "Nginx 可能未完全启动，请稍后检查"
    fi
}

# 配置防火墙
configure_firewall() {
    print_info "配置防火墙..."

    if command -v ufw &> /dev/null; then
        # 允许 HTTP 和 HTTPS
        ufw allow 80/tcp
        ufw allow 443/tcp

        # 如果 UFW 未启用，询问是否启用
        if ! ufw status | grep -q "Status: active"; then
            print_warning "UFW 防火墙未启用"
            print_info "建议启用防火墙以提高安全性"
            print_info "启用命令: ufw enable"
        else
            print_success "防火墙规则配置完成"
        fi
    else
        print_info "未检测到 UFW 防火墙"
    fi
}

# 打印部署信息
print_deployment_info() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}║                 部署成功！                                ║${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}访问地址:${NC}"
    echo -e "  前端应用: ${GREEN}http://$SERVER_IP${NC}"
    echo -e "  后端 API: ${GREEN}http://$SERVER_IP/api/${NC}"
    echo -e "  健康检查: ${GREEN}http://$SERVER_IP/health${NC}"
    echo ""
    echo -e "${BLUE}常用命令:${NC}"
    echo -e "  查看容器状态:   ${YELLOW}cd $PROJECT_DIR/deploy/docker && docker compose ps${NC}"
    echo -e "  查看日志:       ${YELLOW}cd $PROJECT_DIR/deploy/docker && docker compose logs -f${NC}"
    echo -e "  停止服务:       ${YELLOW}cd $PROJECT_DIR/deploy/docker && docker compose down${NC}"
    echo -e "  重启服务:       ${YELLOW}cd $PROJECT_DIR/deploy/docker && docker compose restart${NC}"
    echo -e "  重新构建:       ${YELLOW}cd $PROJECT_DIR/deploy/docker && docker compose up -d --build${NC}"
    echo ""
    echo -e "${BLUE}项目目录:${NC}"
    echo -e "  项目根目录:     ${GREEN}$PROJECT_DIR${NC}"
    echo -e "  数据目录:       ${GREEN}$PROJECT_DIR/data${NC}"
    echo -e "  结果目录:       ${GREEN}$PROJECT_DIR/result${NC}"
    echo -e "  日志目录:       ${GREEN}$PROJECT_DIR/logs${NC}"
    echo ""
    echo -e "${BLUE}Docker 容器:${NC}"
    echo -e "  后端容器:       ${GREEN}dimensio-backend${NC}"
    echo -e "  前端容器:       ${GREEN}dimensio-frontend${NC}"
    echo -e "  Nginx容器:      ${GREEN}dimensio-nginx${NC}"
    echo ""
}

# 主函数
main() {
    print_banner

    # 执行部署步骤
    check_root
    check_os
    update_system
    install_docker
    configure_docker_registry  # 配置镜像加速器
    install_docker_compose
    check_project_dir
    create_directories
    stop_old_containers
    clean_old_images
    build_and_start
    check_containers
    test_services
    configure_firewall

    # 打印部署信息
    print_deployment_info

    print_success "部署完成！"
}

# 运行主函数
main
