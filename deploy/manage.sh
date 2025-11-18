#!/bin/bash

##############################################################################
# Dimensio 服务管理脚本
# 用于日常维护和管理
##############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_DIR="/root/dimensio"
DOCKER_DIR="$PROJECT_DIR/deploy/docker"

# 打印函数
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 显示帮助信息
show_help() {
    echo -e "${GREEN}Dimensio 服务管理脚本${NC}"
    echo ""
    echo "用法: ./manage.sh [命令]"
    echo ""
    echo "可用命令:"
    echo "  start        启动所有服务"
    echo "  stop         停止所有服务"
    echo "  restart      重启所有服务"
    echo "  status       查看服务状态"
    echo "  logs         查看服务日志"
    echo "  logs-f       实时查看服务日志"
    echo "  update       更新并重新部署"
    echo "  rebuild      重新构建镜像"
    echo "  clean        清理未使用的 Docker 资源"
    echo "  backup       备份数据和结果目录"
    echo "  test         测试服务连接"
    echo "  shell        进入后端容器"
    echo "  help         显示此帮助信息"
    echo ""
}

# 启动服务
start_service() {
    print_info "启动服务..."
    cd "$DOCKER_DIR"
    docker-compose up -d
    print_success "服务已启动"
    show_status
}

# 停止服务
stop_service() {
    print_info "停止服务..."
    cd "$DOCKER_DIR"
    docker-compose down
    print_success "服务已停止"
}

# 重启服务
restart_service() {
    print_info "重启服务..."
    cd "$DOCKER_DIR"
    docker-compose restart
    print_success "服务已重启"
    show_status
}

# 查看状态
show_status() {
    print_info "服务状态:"
    cd "$DOCKER_DIR"
    docker-compose ps
}

# 查看日志
show_logs() {
    print_info "查看日志（最近100行）..."
    cd "$DOCKER_DIR"
    docker-compose logs --tail=100
}

# 实时查看日志
show_logs_follow() {
    print_info "实时查看日志（按 Ctrl+C 退出）..."
    cd "$DOCKER_DIR"
    docker-compose logs -f
}

# 更新并重新部署
update_service() {
    print_info "更新服务..."

    # 如果是 Git 仓库，拉取最新代码
    if [ -d "$PROJECT_DIR/.git" ]; then
        print_info "拉取最新代码..."
        cd "$PROJECT_DIR"
        git pull origin main || git pull origin master
    fi

    print_info "重新构建并启动..."
    cd "$DOCKER_DIR"
    docker-compose down
    docker-compose up -d --build

    print_success "更新完成"
    show_status
}

# 重新构建
rebuild_service() {
    print_info "重新构建镜像..."
    cd "$DOCKER_DIR"
    docker-compose build --no-cache
    docker-compose up -d
    print_success "重新构建完成"
    show_status
}

# 清理资源
clean_docker() {
    print_warning "这将清理所有未使用的 Docker 资源"
    read -p "确认继续? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "清理 Docker 资源..."
        docker system prune -a -f
        print_success "清理完成"
    else
        print_info "已取消"
    fi
}

# 备份数据
backup_data() {
    print_info "备份数据..."

    BACKUP_DIR="$PROJECT_DIR/backups"
    mkdir -p "$BACKUP_DIR"

    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/dimensio_backup_$TIMESTAMP.tar.gz"

    cd "$PROJECT_DIR"
    tar -czf "$BACKUP_FILE" data/ result/ logs/

    print_success "备份完成: $BACKUP_FILE"
    print_info "备份大小: $(du -h $BACKUP_FILE | cut -f1)"
}

# 测试服务
test_service() {
    print_info "测试服务连接..."

    # 测试后端
    echo -n "后端 API: "
    if curl -s -f http://localhost:5000/ > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
    fi

    # 测试 Nginx
    echo -n "Nginx: "
    if curl -s -f http://localhost/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
    fi

    # 测试前端
    echo -n "前端: "
    if curl -s -f http://localhost/ > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
    fi
}

# 进入容器
enter_shell() {
    print_info "进入后端容器..."
    cd "$DOCKER_DIR"
    docker-compose exec backend bash || docker-compose exec backend sh
}

# 主函数
main() {
    if [ ! -d "$DOCKER_DIR" ]; then
        print_error "项目目录不存在: $DOCKER_DIR"
        exit 1
    fi

    case "$1" in
        start)
            start_service
            ;;
        stop)
            stop_service
            ;;
        restart)
            restart_service
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        logs-f)
            show_logs_follow
            ;;
        update)
            update_service
            ;;
        rebuild)
            rebuild_service
            ;;
        clean)
            clean_docker
            ;;
        backup)
            backup_data
            ;;
        test)
            test_service
            ;;
        shell)
            enter_shell
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
