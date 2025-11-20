#!/bin/bash
###############################################################################
# Dimensio 一键快速安装脚本（Ubuntu 系统）
#
# 此脚本会自动完成以下操作：
# 1. 检查并安装 Python 3.8
# 2. 安装系统依赖（git, nginx, nodejs, npm）
# 3. 配置并部署 Dimensio
#
# 用法:
#   sudo ./quick-install.sh
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

# 打印横幅
print_banner() {
    echo ""
    echo "=========================================="
    echo "  Dimensio 一键快速安装脚本"
    echo "  适用于 Ubuntu 系统"
    echo "=========================================="
    echo ""
}

# 检查 root 权限
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用 sudo 运行此脚本"
        exit 1
    fi
}

# 检测操作系统
check_os() {
    log_info "检测操作系统..."

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        log_error "无法检测操作系统"
        exit 1
    fi

    if [ "$OS" != "ubuntu" ]; then
        log_warning "此脚本针对 Ubuntu 优化，但会尝试在 $OS 上运行"
    fi

    log_success "操作系统: $OS $OS_VERSION"
}

# 安装 Python 3.8
install_python38() {
    log_info "检查 Python 3.8..."

    if command -v python3.8 &> /dev/null; then
        PY_VERSION=$(python3.8 --version 2>&1)
        log_success "Python 3.8 已安装: $PY_VERSION"
        return 0
    fi

    log_info "安装 Python 3.8..."

    # 添加 deadsnakes PPA
    log_info "添加 deadsnakes PPA..."
    apt update
    apt install -y software-properties-common
    add-apt-repository -y ppa:deadsnakes/ppa
    apt update

    # 安装 Python 3.8 及相关包
    log_info "安装 Python 3.8 及相关包..."
    apt install -y \
        python3.8 \
        python3.8-venv \
        python3.8-dev \
        python3.8-distutils

    # 安装 pip
    log_info "安装 pip for Python 3.8..."
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3.8

    # 验证安装
    if command -v python3.8 &> /dev/null; then
        PY_VERSION=$(python3.8 --version 2>&1)
        log_success "✓ Python 3.8 安装成功: $PY_VERSION"
    else
        log_error "Python 3.8 安装失败"
        exit 1
    fi
}

# 安装系统依赖
install_system_deps() {
    log_info "安装系统依赖..."

    apt update

    # 安装 Git
    if ! command -v git &> /dev/null; then
        log_info "安装 Git..."
        apt install -y git
    else
        log_success "✓ Git 已安装"
    fi

    # 安装 Nginx
    if ! command -v nginx &> /dev/null; then
        log_info "安装 Nginx..."
        apt install -y nginx
    else
        log_success "✓ Nginx 已安装"
    fi

    # 安装 Curl
    if ! command -v curl &> /dev/null; then
        log_info "安装 Curl..."
        apt install -y curl
    else
        log_success "✓ Curl 已安装"
    fi

    # 安装 Node.js 和 npm
    if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
        log_info "安装 Node.js 和 npm..."

        # 安装 NodeSource repository (Node.js 18.x LTS)
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt install -y nodejs

        NODE_VERSION=$(node --version 2>&1)
        NPM_VERSION=$(npm --version 2>&1)
        log_success "✓ Node.js 已安装: $NODE_VERSION"
        log_success "✓ npm 已安装: $NPM_VERSION"
    else
        log_success "✓ Node.js 和 npm 已安装"
    fi

    # 安装其他可能需要的工具
    log_info "安装辅助工具..."
    apt install -y \
        build-essential \
        rsync \
        tree

    log_success "所有系统依赖已安装"
}

# 创建部署目录
setup_deploy_directory() {
    DEPLOY_PATH=${DEPLOY_PATH:-/root/workspace/dimensio}

    log_info "设置部署目录: $DEPLOY_PATH"

    if [ -d "$DEPLOY_PATH" ]; then
        log_warning "部署目录已存在"
        read -p "是否覆盖现有部署? [y/N]: " OVERWRITE

        if [ "$OVERWRITE" != "y" ] && [ "$OVERWRITE" != "Y" ]; then
            log_info "保持现有部署，跳过目录创建"
            return 0
        fi

        # 备份现有部署
        BACKUP_NAME="${DEPLOY_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "备份现有部署到: $BACKUP_NAME"
        mv "$DEPLOY_PATH" "$BACKUP_NAME"
    fi

    mkdir -p "$DEPLOY_PATH"
    log_success "部署目录已创建"
}

# 复制项目文件
copy_project_files() {
    log_info "复制项目文件到部署目录..."

    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    DEPLOY_PATH=${DEPLOY_PATH:-/root/workspace/dimensio}

    rsync -av --exclude='deploy' --exclude='.git' --exclude='venv' \
          --exclude='node_modules' --exclude='data' --exclude='result' \
          "$PROJECT_ROOT/" "$DEPLOY_PATH/"

    # 复制 deploy 目录（但不包括备份文件）
    mkdir -p "$DEPLOY_PATH/deploy"
    rsync -av --exclude='*.backup.*' \
          "$SCRIPT_DIR/" "$DEPLOY_PATH/deploy/"

    log_success "项目文件已复制"
}

# 创建环境配置文件
create_env_file() {
    log_info "创建环境配置文件..."

    DEPLOY_PATH=${DEPLOY_PATH:-/root/workspace/dimensio}
    ENV_FILE="$DEPLOY_PATH/deploy/.env"

    if [ -f "$ENV_FILE" ]; then
        log_warning ".env 文件已存在，跳过创建"
        return 0
    fi

    cat > "$ENV_FILE" << 'EOF'
# Dimensio 部署配置

# 部署路径
DEPLOY_PATH=/root/workspace/dimensio

# 服务器域名或 IP
SERVER_NAME=localhost

# Python 命令（使用 Python 3.8）
PYTHON_CMD=python3.8

# API 配置
API_PORT=5000
API_WORKERS=4
API_TIMEOUT=600

# 日志目录
LOG_DIR=/var/log/dimensio

# 数据目录
DATA_DIR=/root/workspace/dimensio/data
RESULT_DIR=/root/workspace/dimensio/result

# 服务运行用户
SERVICE_USER=www-data
SERVICE_GROUP=www-data

# 备份配置
BACKUP_DIR=/var/backups/dimensio
BACKUP_KEEP=7
EOF

    log_success "环境配置文件已创建: $ENV_FILE"
    log_info "如需修改配置，请编辑: $ENV_FILE"
}

# 主安装流程
main() {
    print_banner

    check_root
    check_os

    log_info "开始安装 Dimensio..."
    echo ""

    # 步骤 1: 安装 Python 3.8
    log_info "=========================================="
    log_info "步骤 1/5: 安装 Python 3.8"
    log_info "=========================================="
    install_python38
    echo ""

    # 步骤 2: 安装系统依赖
    log_info "=========================================="
    log_info "步骤 2/5: 安装系统依赖"
    log_info "=========================================="
    install_system_deps
    echo ""

    # 步骤 3: 设置部署目录
    log_info "=========================================="
    log_info "步骤 3/5: 设置部署目录"
    log_info "=========================================="
    setup_deploy_directory
    copy_project_files
    create_env_file
    echo ""

    # 步骤 4: 运行主部署脚本
    log_info "=========================================="
    log_info "步骤 4/5: 部署应用"
    log_info "=========================================="

    DEPLOY_PATH=${DEPLOY_PATH:-/root/workspace/dimensio}
    cd "$DEPLOY_PATH/deploy"

    # 调用主部署脚本
    ./deploy.sh install

    echo ""

    # 步骤 5: 完成
    log_info "=========================================="
    log_success "安装完成！"
    log_info "=========================================="
    echo ""

    log_info "服务已启动，可以通过以下方式访问："
    echo ""
    echo "  前端: http://$(hostname -I | awk '{print $1}')"
    echo "  API:  http://$(hostname -I | awk '{print $1}')/api/"
    echo ""

    log_info "常用管理命令："
    echo "  cd $DEPLOY_PATH/deploy"
    echo ""
    echo "  sudo ./deploy.sh status   - 查看服务状态"
    echo "  sudo ./deploy.sh restart  - 重启服务"
    echo "  sudo ./deploy.sh logs     - 查看日志"
    echo "  sudo ./deploy.sh stop     - 停止服务"
    echo "  sudo ./deploy.sh backup   - 备份数据"
    echo ""

    log_info "如需重新配置，请编辑："
    echo "  $DEPLOY_PATH/deploy/.env"
    echo ""
}

# 运行主函数
main "$@"
