#!/bin/bash
###############################################################################
# Dimensio Compression Service Shell Wrapper
#
# 这是一个便捷的 Shell 脚本包装器，用于从其他系统或定时任务调用
# Dimensio 压缩服务。
#
# 用法:
#   ./run_compression.sh [options]
#
# 选项:
#   -d, --data-dir DIR      数据目录（默认: ./data）
#   -r, --result-dir DIR    结果目录（默认: ./result）
#   -h, --history FILES     历史文件列表，空格分隔（可选）
#   -v, --verbose           启用详细日志
#   -s, --create-samples    创建示例配置文件
#   --help                  显示帮助信息
#
# 示例:
#   # 使用默认配置
#   ./run_compression.sh
#
#   # 使用自定义目录
#   ./run_compression.sh -d ./my_data -r ./my_results
#
#   # 多个历史文件
#   ./run_compression.sh -h "history1.json history2.json history3.json"
#
#   # 启用详细日志
#   ./run_compression.sh -v
#
###############################################################################

# 默认值
DATA_DIR="./data"
RESULT_DIR="./result"
HISTORY_FILES=""
VERBOSE=0
CREATE_SAMPLES=0

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

# 显示帮助
show_help() {
    cat << EOF
Dimensio Compression Service Shell Wrapper

用法: $0 [options]

选项:
  -d, --data-dir DIR      数据目录（默认: ./data）
  -r, --result-dir DIR    结果目录（默认: ./result）
  -h, --history FILES     历史文件列表，空格分隔（可选）
  -v, --verbose           启用详细日志
  -s, --create-samples    创建示例配置文件并退出
  --help                  显示此帮助信息

示例:
  # 使用默认配置
  $0

  # 使用自定义目录
  $0 -d ./my_data -r ./my_results

  # 多个历史文件
  $0 -h "history1.json history2.json history3.json"

  # 启用详细日志
  $0 -v

  # 创建示例配置
  $0 -s

EOF
    exit 0
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--data-dir)
            DATA_DIR="$2"
            shift 2
            ;;
        -r|--result-dir)
            RESULT_DIR="$2"
            shift 2
            ;;
        -h|--history)
            HISTORY_FILES="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -s|--create-samples)
            CREATE_SAMPLES=1
            shift
            ;;
        --help)
            show_help
            ;;
        *)
            log_error "未知选项: $1"
            echo "使用 --help 查看帮助信息"
            exit 1
            ;;
    esac
done

# 检查 Python 是否安装
if ! command -v python &> /dev/null && ! command -v python3 &> /dev/null; then
    log_error "Python 未安装或不在 PATH 中"
    exit 1
fi

# 优先使用 python3
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
else
    PYTHON_CMD="python"
fi

# 检查脚本是否存在
if [ ! -f "run_compression.py" ]; then
    log_error "run_compression.py 脚本未找到"
    log_error "请确保在正确的目录中运行此脚本"
    exit 1
fi

# 创建示例配置
if [ $CREATE_SAMPLES -eq 1 ]; then
    log_info "创建示例配置文件..."
    $PYTHON_CMD run_compression.py --create-samples
    exit $?
fi

# 构建命令
CMD="$PYTHON_CMD run_compression.py"
CMD="$CMD --data-dir \"$DATA_DIR\""
CMD="$CMD --result-dir \"$RESULT_DIR\""

if [ -n "$HISTORY_FILES" ]; then
    CMD="$CMD --history $HISTORY_FILES"
fi

if [ $VERBOSE -eq 1 ]; then
    CMD="$CMD --verbose"
fi

# 显示执行信息
log_info "========================================"
log_info "Dimensio Compression Service"
log_info "========================================"
log_info "数据目录: $DATA_DIR"
log_info "结果目录: $RESULT_DIR"
if [ -n "$HISTORY_FILES" ]; then
    log_info "历史文件: $HISTORY_FILES"
else
    log_info "历史文件: 自动发现"
fi
log_info "详细日志: $([ $VERBOSE -eq 1 ] && echo '启用' || echo '禁用')"
log_info "========================================"
echo ""

# 执行压缩
log_info "开始执行压缩..."
eval $CMD
EXIT_CODE=$?

# 检查结果
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    log_success "压缩完成!"

    # 查找最新的结果目录
    LATEST_RESULT=$(ls -t "$RESULT_DIR" 2>/dev/null | head -1)
    if [ -n "$LATEST_RESULT" ]; then
        log_info "结果保存在: $RESULT_DIR/$LATEST_RESULT"

        # 如果存在 result_summary.json，显示摘要
        SUMMARY_FILE="$RESULT_DIR/$LATEST_RESULT/result_summary.json"
        if [ -f "$SUMMARY_FILE" ]; then
            log_info "结果摘要:"
            if command -v jq &> /dev/null; then
                # 如果安装了 jq，使用它来格式化 JSON
                cat "$SUMMARY_FILE" | jq '.'
            else
                # 否则直接显示
                cat "$SUMMARY_FILE"
            fi
        fi
    fi
else
    log_error "压缩失败（退出码: $EXIT_CODE）"

    # 提供故障排查建议
    echo ""
    log_warning "故障排查建议:"
    echo "  1. 确保配置文件存在于 $DATA_DIR/"
    echo "  2. 检查配置文件格式是否正确"
    echo "  3. 使用 -v 选项查看详细日志"
    echo "  4. 使用 -s 选项创建示例配置文件"
    echo ""
fi

exit $EXIT_CODE
