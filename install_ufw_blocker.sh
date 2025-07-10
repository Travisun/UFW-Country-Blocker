#!/bin/bash

# UFW CIDR Blocker 安装脚本
# 用于安装和配置UFW CIDR阻止器脚本

set -e

# 配置变量
SCRIPT_NAME="ufw_cidr_blocker"
SCRIPT_FILE="ufw_cidr_blocker.sh"
INSTALL_DIR="/usr/local/bin"
SERVICE_NAME="${SCRIPT_NAME}"
CRON_JOB_USER="root"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否以root权限运行
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "此安装脚本需要root权限运行"
        exit 1
    fi
}

# 检查依赖
check_dependencies() {
    log_info "检查系统依赖..."
    
    # 检查UFW
    if ! command -v ufw > /dev/null 2>&1; then
        log_error "UFW未安装，请先安装UFW: sudo apt install ufw"
        exit 1
    fi
    
    # 检查curl
    if ! command -v curl > /dev/null 2>&1; then
        log_warn "curl未安装，正在安装..."
        apt update && apt install -y curl
    fi
    
    # 检查cron
    if ! command -v cron > /dev/null 2>&1; then
        log_warn "cron未安装，正在安装..."
        apt update && apt install -y cron
    fi
    
    log_info "所有依赖检查完成"
}

# 安装脚本
install_script() {
    log_info "安装UFW CIDR阻止器脚本..."
    
    # 检查脚本文件是否存在
    if [ ! -f "$SCRIPT_FILE" ]; then
        log_error "脚本文件 $SCRIPT_FILE 不存在"
        exit 1
    fi
    
    # 复制脚本到安装目录
    cp "$SCRIPT_FILE" "$INSTALL_DIR/$SCRIPT_NAME"
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
    
    log_info "脚本已安装到 $INSTALL_DIR/$SCRIPT_NAME"
}

# 创建日志目录
create_log_dir() {
    log_info "创建日志目录..."
    mkdir -p /var/log
    touch "/var/log/${SCRIPT_NAME}.log"
    chmod 644 "/var/log/${SCRIPT_NAME}.log"
    log_info "日志文件已创建: /var/log/${SCRIPT_NAME}.log"
}

# 设置定时任务
setup_cron() {
    log_info "设置定时任务..."
    
    # 询问用户定时频率
    echo "请选择定时任务频率:"
    echo "1) 每小时执行"
    echo "2) 每天执行"
    echo "3) 每周执行"
    echo "4) 自定义cron表达式"
    echo "5) 不设置定时任务"
    
    read -p "请选择 (1-5): " choice
    
    case $choice in
        1)
            cron_expression="0 * * * *"
            description="每小时执行"
            ;;
        2)
            cron_expression="0 0 * * *"
            description="每天午夜执行"
            ;;
        3)
            cron_expression="0 0 * * 0"
            description="每周日午夜执行"
            ;;
        4)
            read -p "请输入自定义cron表达式 (例如: 0 2 * * * 表示每天凌晨2点): " cron_expression
            description="自定义时间执行"
            ;;
        5)
            log_info "跳过定时任务设置"
            return
            ;;
        *)
            log_error "无效选择"
            exit 1
            ;;
    esac
    
    # 创建临时crontab文件
    temp_cron=$(mktemp)
    
    # 导出当前crontab
    crontab -u "$CRON_JOB_USER" -l 2>/dev/null > "$temp_cron" || true
    
    # 检查是否已存在相同的定时任务
    if grep -q "$INSTALL_DIR/$SCRIPT_NAME" "$temp_cron"; then
        log_warn "发现已存在的定时任务，将更新为新的设置"
        # 删除旧的定时任务行
        sed -i "/$INSTALL_DIR\/$SCRIPT_NAME/d" "$temp_cron"
    fi
    
    # 添加新的定时任务
    echo "# UFW CIDR Blocker - $description" >> "$temp_cron"
    echo "$cron_expression $INSTALL_DIR/$SCRIPT_NAME >> /var/log/${SCRIPT_NAME}.log 2>&1" >> "$temp_cron"
    
    # 安装新的crontab
    crontab -u "$CRON_JOB_USER" "$temp_cron"
    
    # 清理临时文件
    rm -f "$temp_cron"
    
    log_info "定时任务已设置: $description"
    log_info "Cron表达式: $cron_expression"
}

# 测试脚本
test_script() {
    log_info "测试脚本功能..."
    
    read -p "是否要现在测试脚本? (y/N): " test_choice
    
    if [[ $test_choice =~ ^[Yy]$ ]]; then
        log_info "运行测试..."
        if "$INSTALL_DIR/$SCRIPT_NAME"; then
            log_info "脚本测试成功"
        else
            log_warn "脚本测试失败，请检查日志文件"
        fi
    else
        log_info "跳过测试"
    fi
}

# 显示使用说明
show_usage() {
    echo ""
    log_info "安装完成！"
    echo ""
    echo "使用说明:"
    echo "1. 手动运行脚本: sudo $INSTALL_DIR/$SCRIPT_NAME"
    echo "2. 查看日志: tail -f /var/log/${SCRIPT_NAME}.log"
    echo "3. 查看UFW状态: sudo ufw status numbered"
    echo "4. 编辑定时任务: sudo crontab -e"
    echo ""
    echo "脚本功能:"
    echo "- 自动下载最新的CIDR列表"
    echo "- 阻止指定CIDR访问53端口 (TCP/UDP)"
    echo "- 阻止指定CIDR的ping请求"
    echo "- 自动清理旧规则并应用新规则"
    echo "- 完整的日志记录"
    echo ""
}

# 主函数
main() {
    echo "=========================================="
    echo "    UFW CIDR Blocker 安装程序"
    echo "=========================================="
    echo ""
    
    # 检查权限
    check_root
    
    # 检查依赖
    check_dependencies
    
    # 安装脚本
    install_script
    
    # 创建日志目录
    create_log_dir
    
    # 设置定时任务
    setup_cron
    
    # 测试脚本
    test_script
    
    # 显示使用说明
    show_usage
}

# 运行主函数
main "$@" 