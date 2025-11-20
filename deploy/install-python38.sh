#!/bin/bash
###############################################################################
# Python 3.8.20 安装脚本
# 用于在 Ubuntu/Debian 系统上安装 Python 3.8.20
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

PYTHON_VERSION="3.8.20"
PYTHON_SHORT_VERSION="3.8"

echo ""
log_info "=========================================="
log_info "Python ${PYTHON_VERSION} 安装脚本"
log_info "=========================================="
echo ""

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
    log_error "请使用 sudo 运行此脚本"
    exit 1
fi

# 检测操作系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VERSION=$VERSION_ID
else
    log_error "无法检测操作系统"
    exit 1
fi

log_info "操作系统: $OS $OS_VERSION"
echo ""

# 检查当前 Python 版本
if command -v python${PYTHON_SHORT_VERSION} &> /dev/null; then
    CURRENT_VERSION=$(python${PYTHON_SHORT_VERSION} --version 2>&1 | awk '{print $2}')
    log_info "已安装的 Python ${PYTHON_SHORT_VERSION} 版本: $CURRENT_VERSION"

    if [ "$CURRENT_VERSION" == "$PYTHON_VERSION" ]; then
        log_success "Python ${PYTHON_VERSION} 已安装"
        exit 0
    fi
fi

# 方案选择
log_info "选择安装方案:"
echo "  1. 使用 deadsnakes PPA (推荐 - Ubuntu)"
echo "  2. 从源码编译 (所有系统通用)"
echo ""
read -p "请选择 [1/2]: " CHOICE

case $CHOICE in
    1)
        install_from_ppa
        ;;
    2)
        install_from_source
        ;;
    *)
        log_error "无效的选择"
        exit 1
        ;;
esac

# 使用 deadsnakes PPA 安装（仅 Ubuntu）
install_from_ppa() {
    log_info "使用 deadsnakes PPA 安装 Python ${PYTHON_SHORT_VERSION}..."

    if [ "$OS" != "ubuntu" ]; then
        log_error "deadsnakes PPA 仅支持 Ubuntu"
        log_info "请选择从源码编译安装"
        exit 1
    fi

    # 安装依赖
    log_info "安装依赖..."
    apt update
    apt install -y software-properties-common

    # 添加 PPA
    log_info "添加 deadsnakes PPA..."
    add-apt-repository -y ppa:deadsnakes/ppa
    apt update

    # 安装 Python 3.8
    log_info "安装 Python ${PYTHON_SHORT_VERSION} 及相关包..."
    apt install -y \
        python${PYTHON_SHORT_VERSION} \
        python${PYTHON_SHORT_VERSION}-venv \
        python${PYTHON_SHORT_VERSION}-dev \
        python${PYTHON_SHORT_VERSION}-distutils

    # 安装 pip
    log_info "安装 pip..."
    curl -sS https://bootstrap.pypa.io/get-pip.py | python${PYTHON_SHORT_VERSION}

    verify_installation
}

# 从源码编译安装
install_from_source() {
    log_info "从源码编译安装 Python ${PYTHON_VERSION}..."

    # 安装编译依赖
    log_info "安装编译依赖..."
    case $OS in
        ubuntu|debian)
            apt update
            apt install -y \
                build-essential \
                zlib1g-dev \
                libncurses5-dev \
                libgdbm-dev \
                libnss3-dev \
                libssl-dev \
                libreadline-dev \
                libffi-dev \
                libsqlite3-dev \
                wget \
                libbz2-dev \
                liblzma-dev
            ;;
        centos|rhel|rocky|almalinux)
            yum groupinstall -y "Development Tools"
            yum install -y \
                zlib-devel \
                bzip2-devel \
                openssl-devel \
                ncurses-devel \
                sqlite-devel \
                readline-devel \
                tk-devel \
                gdbm-devel \
                db4-devel \
                libpcap-devel \
                xz-devel \
                expat-devel \
                wget
            ;;
        *)
            log_error "不支持的操作系统: $OS"
            exit 1
            ;;
    esac

    # 下载 Python 源码
    log_info "下载 Python ${PYTHON_VERSION} 源码..."
    cd /tmp

    if [ -f "Python-${PYTHON_VERSION}.tgz" ]; then
        log_info "源码已存在，跳过下载"
    else
        wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
    fi

    # 解压
    log_info "解压源码..."
    tar -xzf Python-${PYTHON_VERSION}.tgz
    cd Python-${PYTHON_VERSION}

    # 配置
    log_info "配置编译选项..."
    ./configure --enable-optimizations --with-ensurepip=install

    # 编译（使用多核）
    CORES=$(nproc)
    log_info "编译 Python (使用 $CORES 核心，这可能需要 10-20 分钟)..."
    make -j $CORES

    # 安装
    log_info "安装 Python..."
    make altinstall  # 使用 altinstall 不覆盖系统 python3

    # 清理
    log_info "清理临时文件..."
    cd /tmp
    rm -rf Python-${PYTHON_VERSION} Python-${PYTHON_VERSION}.tgz

    verify_installation
}

# 验证安装
verify_installation() {
    echo ""
    log_info "验证安装..."

    if command -v python${PYTHON_SHORT_VERSION} &> /dev/null; then
        INSTALLED_VERSION=$(python${PYTHON_SHORT_VERSION} --version 2>&1 | awk '{print $2}')
        log_success "Python ${PYTHON_SHORT_VERSION} 已成功安装"
        log_info "版本: $INSTALLED_VERSION"

        # 验证 pip
        if python${PYTHON_SHORT_VERSION} -m pip --version &> /dev/null; then
            PIP_VERSION=$(python${PYTHON_SHORT_VERSION} -m pip --version | awk '{print $2}')
            log_success "pip 版本: $PIP_VERSION"
        else
            log_warning "pip 未安装，尝试安装..."
            curl -sS https://bootstrap.pypa.io/get-pip.py | python${PYTHON_SHORT_VERSION}
        fi

        # 验证 venv
        if python${PYTHON_SHORT_VERSION} -m venv --help &> /dev/null; then
            log_success "venv 模块可用"
        else
            log_error "venv 模块不可用"
        fi

        echo ""
        log_success "=========================================="
        log_success "Python ${PYTHON_SHORT_VERSION} 安装完成！"
        log_success "=========================================="
        echo ""
        log_info "使用方法:"
        echo "  python${PYTHON_SHORT_VERSION} --version"
        echo "  python${PYTHON_SHORT_VERSION} -m venv myenv"
        echo ""

    else
        log_error "Python ${PYTHON_SHORT_VERSION} 安装失败"
        exit 1
    fi
}

# 主逻辑
case $CHOICE in
    1)
        install_from_ppa
        ;;
    2)
        install_from_source
        ;;
esac
