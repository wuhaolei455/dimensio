#!/bin/bash
###############################################################################
# Dimensio 一键部署脚本
#
# 用法:
#   sudo ./deploy.sh [选项]
#
# 选项:
#   install     - 全新安装（首次部署）
#   update      - 更新代码并重启服务
#   restart     - 仅重启服务
#   stop        - 停止服务
#   status      - 查看服务状态
#   backup      - 备份数据和配置
#   rollback    - 回滚到上一个版本
#   logs        - 查看日志
#   clean       - 清理临时文件
#
###############################################################################

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
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

# 脚本目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 加载环境变量
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
    log_info "已加载环境配置: $SCRIPT_DIR/.env"
else
    log_warning ".env 文件不存在，使用默认配置"
    # 默认配置
    DEPLOY_PATH=${DEPLOY_PATH:-/root/workspace/dimensio}
    SERVER_NAME=${SERVER_NAME:-localhost}
    PYTHON_CMD=${PYTHON_CMD:-python3}
    API_PORT=${API_PORT:-5000}
    API_WORKERS=${API_WORKERS:-4}
    API_TIMEOUT=${API_TIMEOUT:-600}
    LOG_DIR=${LOG_DIR:-/var/log/dimensio}
    DATA_DIR=${DATA_DIR:-${DEPLOY_PATH}/data}
    RESULT_DIR=${RESULT_DIR:-${DEPLOY_PATH}/result}
    SERVICE_USER=${SERVICE_USER:-www-data}
    SERVICE_GROUP=${SERVICE_GROUP:-www-data}
    BACKUP_DIR=${BACKUP_DIR:-/var/backups/dimensio}
    BACKUP_KEEP=${BACKUP_KEEP:-7}
fi

# 检查 root 权限
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用 sudo 运行此脚本"
        exit 1
    fi
}

# 检查系统依赖
check_dependencies() {
    log_info "检查系统依赖..."

    local deps=("git" "nginx" "curl")
    local missing_deps=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    # 检查 Node.js
    if ! command -v node &> /dev/null; then
        missing_deps+=("nodejs")
    fi

    # 检查 npm
    if ! command -v npm &> /dev/null; then
        missing_deps+=("npm")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "缺少以下依赖: ${missing_deps[*]}"
        log_info "在 Ubuntu/Debian 上，可以运行："
        echo "  sudo apt update"
        echo "  sudo apt install -y ${missing_deps[*]}"
        exit 1
    fi

    log_success "所有依赖已安装"
}

# 创建必要的目录
create_directories() {
    log_info "创建必要的目录..."

    mkdir -p "$LOG_DIR"
    mkdir -p "$DATA_DIR"
    mkdir -p "$RESULT_DIR"
    mkdir -p "$BACKUP_DIR"

    # 设置权限
    chown -R "$SERVICE_USER:$SERVICE_GROUP" "$LOG_DIR"
    chown -R "$SERVICE_USER:$SERVICE_GROUP" "$DATA_DIR"
    chown -R "$SERVICE_USER:$SERVICE_GROUP" "$RESULT_DIR"

    log_success "目录创建完成"
}

# 安装 Python 依赖
install_python_deps() {
    log_info "安装 Python 依赖..."

    cd "$DEPLOY_PATH"

    # 创建虚拟环境
    if [ ! -d "venv" ]; then
        log_info "创建 Python 虚拟环境..."
        $PYTHON_CMD -m venv venv
    fi

    # 激活虚拟环境
    source venv/bin/activate

    # 升级 pip
    pip install --upgrade pip

    # 安装项目依赖
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
    fi

    # 安装 API 依赖
    if [ -f "api/requirements.txt" ]; then
        pip install -r api/requirements.txt
    fi

    # 安装 gunicorn
    pip install gunicorn

    log_success "Python 依赖安装完成"
}

# 构建前端
build_frontend() {
    log_info "构建前端..."

    cd "$DEPLOY_PATH/front"

    # 安装依赖
    if [ ! -d "node_modules" ]; then
        log_info "安装前端依赖..."
        npm install
    fi

    # 构建
    log_info "编译前端代码..."
    npm run build

    # 设置权限
    chown -R "$SERVICE_USER:$SERVICE_GROUP" dist

    log_success "前端构建完成"
}

# 配置 Nginx
setup_nginx() {
    log_info "配置 Nginx..."

    # 复制配置文件
    cp "$SCRIPT_DIR/nginx/dimensio.conf" /etc/nginx/sites-available/dimensio

    # 替换配置中的变量
    sed -i "s|your-domain.com|$SERVER_NAME|g" /etc/nginx/sites-available/dimensio
    sed -i "s|/var/www/dimensio|$DEPLOY_PATH|g" /etc/nginx/sites-available/dimensio

    # 创建软链接
    if [ ! -L /etc/nginx/sites-enabled/dimensio ]; then
        ln -s /etc/nginx/sites-available/dimensio /etc/nginx/sites-enabled/dimensio
    fi

    # 测试配置
    nginx -t

    log_success "Nginx 配置完成"
}

# 配置 Systemd 服务
setup_systemd() {
    log_info "配置 Systemd 服务..."

    # 复制服务文件
    cp "$SCRIPT_DIR/systemd/dimensio-api.service" /etc/systemd/system/

    # 替换配置中的变量
    sed -i "s|User=www-data|User=$SERVICE_USER|g" /etc/systemd/system/dimensio-api.service
    sed -i "s|Group=www-data|Group=$SERVICE_GROUP|g" /etc/systemd/system/dimensio-api.service
    sed -i "s|WorkingDirectory=/var/www/dimensio|WorkingDirectory=$DEPLOY_PATH|g" /etc/systemd/system/dimensio-api.service
    sed -i "s|127.0.0.1:5000|127.0.0.1:$API_PORT|g" /etc/systemd/system/dimensio-api.service
    sed -i "s|--workers 4|--workers $API_WORKERS|g" /etc/systemd/system/dimensio-api.service
    sed -i "s|--timeout 600|--timeout $API_TIMEOUT|g" /etc/systemd/system/dimensio-api.service

    # 重载 systemd
    systemctl daemon-reload

    log_success "Systemd 服务配置完成"
}

# 启动服务
start_services() {
    log_info "启动服务..."

    # 启动 API 服务
    systemctl enable dimensio-api
    systemctl start dimensio-api

    # 重启 Nginx
    systemctl restart nginx

    log_success "服务启动完成"
}

# 停止服务
stop_services() {
    log_info "停止服务..."

    systemctl stop dimensio-api || true

    log_success "服务已停止"
}

# 重启服务
restart_services() {
    log_info "重启服务..."

    systemctl restart dimensio-api
    systemctl reload nginx

    log_success "服务已重启"
}

# 查看服务状态
show_status() {
    log_info "服务状态："
    echo ""
    echo "========== Dimensio API =========="
    systemctl status dimensio-api --no-pager
    echo ""
    echo "========== Nginx =========="
    systemctl status nginx --no-pager
}

# 备份数据
backup_data() {
    log_info "备份数据和配置..."

    BACKUP_NAME="dimensio_backup_$(date +%Y%m%d_%H%M%S)"
    BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

    mkdir -p "$BACKUP_PATH"

    # 备份数据目录
    if [ -d "$DATA_DIR" ]; then
        cp -r "$DATA_DIR" "$BACKUP_PATH/"
    fi

    # 备份结果目录
    if [ -d "$RESULT_DIR" ]; then
        cp -r "$RESULT_DIR" "$BACKUP_PATH/"
    fi

    # 备份配置文件
    mkdir -p "$BACKUP_PATH/config"
    cp /etc/nginx/sites-available/dimensio "$BACKUP_PATH/config/" 2>/dev/null || true
    cp /etc/systemd/system/dimensio-api.service "$BACKUP_PATH/config/" 2>/dev/null || true
    cp "$SCRIPT_DIR/.env" "$BACKUP_PATH/config/" 2>/dev/null || true

    # 打包
    cd "$BACKUP_DIR"
    tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
    rm -rf "$BACKUP_NAME"

    log_success "备份完成: $BACKUP_DIR/${BACKUP_NAME}.tar.gz"

    # 清理旧备份
    cleanup_old_backups
}

# 清理旧备份
cleanup_old_backups() {
    log_info "清理旧备份（保留最近 $BACKUP_KEEP 个）..."

    cd "$BACKUP_DIR"
    ls -t dimensio_backup_*.tar.gz 2>/dev/null | tail -n +$((BACKUP_KEEP + 1)) | xargs -r rm

    log_success "旧备份清理完成"
}

# 回滚
rollback() {
    log_error "回滚功能需要手动实现，请从备份中恢复"
    echo "备份位置: $BACKUP_DIR"
    ls -lt "$BACKUP_DIR"
}

# 查看日志
show_logs() {
    log_info "查看最近的日志..."
    echo ""
    echo "========== API 访问日志 (最近50行) =========="
    tail -n 50 "$LOG_DIR/access.log" 2>/dev/null || echo "日志文件不存在"
    echo ""
    echo "========== API 错误日志 (最近50行) =========="
    tail -n 50 "$LOG_DIR/error.log" 2>/dev/null || echo "日志文件不存在"
    echo ""
    echo "========== Systemd 日志 (最近50行) =========="
    journalctl -u dimensio-api -n 50 --no-pager
}

# 清理临时文件
clean_temp() {
    log_info "清理临时文件..."

    # 清理 Python 缓存
    find "$DEPLOY_PATH" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find "$DEPLOY_PATH" -type f -name "*.pyc" -delete 2>/dev/null || true

    # 清理 npm 缓存（如果需要）
    # rm -rf "$DEPLOY_PATH/front/node_modules/.cache" 2>/dev/null || true

    log_success "临时文件清理完成"
}

# 全新安装
install() {
    log_info "开始全新安装 Dimensio..."

    check_root
    check_dependencies

    # 创建部署目录
    if [ ! -d "$DEPLOY_PATH" ]; then
        log_info "创建部署目录: $DEPLOY_PATH"
        mkdir -p "$DEPLOY_PATH"
    fi

    # 复制项目文件
    log_info "复制项目文件..."
    rsync -av --exclude='deploy' --exclude='.git' --exclude='venv' --exclude='node_modules' \
          "$PROJECT_ROOT/" "$DEPLOY_PATH/"

    # 设置权限
    chown -R "$SERVICE_USER:$SERVICE_GROUP" "$DEPLOY_PATH"

    create_directories
    install_python_deps
    build_frontend
    setup_nginx
    setup_systemd

    # 创建 .env 文件
    if [ ! -f "$SCRIPT_DIR/.env" ]; then
        log_warning "请创建 $SCRIPT_DIR/.env 配置文件"
        log_info "可以从 $SCRIPT_DIR/.env.example 复制"
    fi

    start_services

    log_success "安装完成！"
    echo ""
    log_info "访问地址: http://$SERVER_NAME"
    log_info "API 地址: http://$SERVER_NAME/api/"
    echo ""
    log_info "使用以下命令管理服务："
    echo "  sudo ./deploy.sh status   - 查看服务状态"
    echo "  sudo ./deploy.sh restart  - 重启服务"
    echo "  sudo ./deploy.sh logs     - 查看日志"
    echo "  sudo ./deploy.sh backup   - 备份数据"
}

# 更新
update() {
    log_info "更新 Dimensio..."

    check_root

    # 备份
    backup_data

    # 停止服务
    stop_services

    # 更新代码
    log_info "更新代码..."
    cd "$PROJECT_ROOT"
    git pull || log_warning "Git 拉取失败，请手动更新代码"

    # 复制文件
    rsync -av --exclude='deploy' --exclude='.git' --exclude='venv' --exclude='node_modules' \
          --exclude='data' --exclude='result' \
          "$PROJECT_ROOT/" "$DEPLOY_PATH/"

    # 更新依赖
    install_python_deps
    build_frontend

    # 重启服务
    start_services

    log_success "更新完成！"
}

# 主函数
main() {
    case "${1:-}" in
        install)
            install
            ;;
        update)
            update
            ;;
        restart)
            check_root
            restart_services
            ;;
        stop)
            check_root
            stop_services
            ;;
        status)
            show_status
            ;;
        backup)
            check_root
            backup_data
            ;;
        rollback)
            rollback
            ;;
        logs)
            show_logs
            ;;
        clean)
            check_root
            clean_temp
            ;;
        *)
            echo "Dimensio 部署脚本"
            echo ""
            echo "用法: sudo $0 {install|update|restart|stop|status|backup|rollback|logs|clean}"
            echo ""
            echo "命令说明:"
            echo "  install   - 全新安装（首次部署）"
            echo "  update    - 更新代码并重启服务"
            echo "  restart   - 仅重启服务"
            echo "  stop      - 停止服务"
            echo "  status    - 查看服务状态"
            echo "  backup    - 备份数据和配置"
            echo "  rollback  - 回滚到上一个版本"
            echo "  logs      - 查看日志"
            echo "  clean     - 清理临时文件"
            exit 1
            ;;
    esac
}

main "$@"
