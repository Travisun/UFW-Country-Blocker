#!/bin/bash

# UFW Country Blocker 一键安装脚本
# 从GitHub自动下载并安装UFW Country Blocker

set -e

# 配置变量
REPO_URL="https://github.com/Travisun/UFW-Country-Blocker"
RAW_URL="https://raw.githubusercontent.com/Travisun/UFW-Country-Blocker/main"
SCRIPT_NAME="ufw_cidr_blocker"
INSTALL_DIR="/usr/local/bin"
SERVICE_NAME="${SCRIPT_NAME}"
CRON_JOB_USER="root"
TEMP_DIR="/tmp/ufw_country_blocker_install"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查是否以root权限运行
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "此安装脚本需要root权限运行"
        echo "请使用: sudo bash install.sh"
        exit 1
    fi
}

# 检查网络连接
check_network() {
    log_step "检查网络连接..."
    if ! curl -s --connect-timeout 10 -f "$RAW_URL/ufw_cidr_blocker.sh" > /dev/null; then
        log_error "无法连接到GitHub，请检查网络连接"
        exit 1
    fi
    log_info "网络连接正常"
}

# 检查依赖
check_dependencies() {
    log_step "检查系统依赖..."
    
    # 检查UFW
    if ! command -v ufw > /dev/null 2>&1; then
        log_warn "UFW未安装，正在安装UFW..."
        apt update && apt install -y ufw
        log_info "UFW安装完成"
    else
        log_info "UFW已安装"
    fi
    
    # 检查curl
    if ! command -v curl > /dev/null 2>&1; then
        log_warn "curl未安装，正在安装..."
        apt update && apt install -y curl
        log_info "curl安装完成"
    else
        log_info "curl已安装"
    fi
    
    # 检查cron
    if ! command -v cron > /dev/null 2>&1; then
        log_warn "cron未安装，正在安装..."
        apt update && apt install -y cron
        log_info "cron安装完成"
    else
        log_info "cron已安装"
    fi
    
    log_info "所有依赖检查完成"
}

# 创建临时目录
create_temp_dir() {
    log_step "创建临时目录..."
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    log_info "临时目录创建完成: $TEMP_DIR"
}

# 下载文件
download_files() {
    log_step "从GitHub下载文件..."
    
    local files=(
        "ufw_cidr_blocker.sh"
        "ufw_cidr_blocker.conf"
    )
    
    for file in "${files[@]}"; do
        log_info "下载 $file..."
        if curl -s -f -o "$file" "$RAW_URL/$file"; then
            log_info "✓ $file 下载成功"
        else
            log_error "✗ $file 下载失败"
            exit 1
        fi
    done
    
    log_info "所有文件下载完成"
}

# 安装脚本
install_script() {
    log_step "安装UFW Country Blocker..."
    
    # 复制主脚本
    cp "ufw_cidr_blocker.sh" "$INSTALL_DIR/$SCRIPT_NAME"
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
    log_info "主脚本已安装到 $INSTALL_DIR/$SCRIPT_NAME"
    
    # 复制配置文件
    cp "ufw_cidr_blocker.conf" "$INSTALL_DIR/ufw_cidr_blocker.conf"
    chmod 644 "$INSTALL_DIR/ufw_cidr_blocker.conf"
    log_info "配置文件已安装到 $INSTALL_DIR/ufw_cidr_blocker.conf"
}

# 创建日志目录
create_log_dir() {
    log_step "创建日志目录..."
    mkdir -p /var/log
    touch "/var/log/${SCRIPT_NAME}.log"
    chmod 644 "/var/log/${SCRIPT_NAME}.log"
    log_info "日志文件已创建: /var/log/${SCRIPT_NAME}.log"
}

# 启用UFW
enable_ufw() {
    log_step "配置UFW防火墙..."
    
    # 检查UFW状态
    if ufw status | grep -q "Status: active"; then
        log_info "UFW已启用"
    else
        log_warn "UFW未启用，正在启用..."
        ufw --force enable
        log_info "UFW已启用"
    fi
    
    # 设置默认策略
    ufw default deny incoming
    ufw default allow outgoing
    log_info "UFW默认策略已设置"
}

# 设置定时任务
setup_cron() {
    log_step "设置定时任务..."
    
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
    
    # 添加新的定时任务 (每周星期一早上3点执行)
    echo "# UFW Country Blocker - 每周星期一早上3点自动更新" >> "$temp_cron"
    echo "0 3 * * 1 $INSTALL_DIR/$SCRIPT_NAME >> /var/log/${SCRIPT_NAME}.log 2>&1" >> "$temp_cron"
    
    # 安装新的crontab
    crontab -u "$CRON_JOB_USER" "$temp_cron"
    
    # 清理临时文件
    rm -f "$temp_cron"
    
    log_info "定时任务已设置: 每周星期一早上3点自动更新"
}

# 测试脚本
test_script() {
    log_step "测试脚本功能..."
    
    log_info "运行测试..."
    if "$INSTALL_DIR/$SCRIPT_NAME" --help > /dev/null 2>&1 || "$INSTALL_DIR/$SCRIPT_NAME" > /dev/null 2>&1; then
        log_info "✓ 脚本测试成功"
    else
        log_warn "⚠ 脚本测试失败，但安装已完成"
    fi
}

# 清理临时文件
cleanup() {
    log_step "清理临时文件..."
    rm -rf "$TEMP_DIR"
    log_info "临时文件清理完成"
}

# 显示使用说明
show_usage() {
    echo ""
    echo "=========================================="
    echo "    UFW Country Blocker 安装完成！"
    echo "=========================================="
    echo ""
    log_info "安装位置:"
    echo "  主脚本: $INSTALL_DIR/$SCRIPT_NAME"
    echo "  配置文件: $INSTALL_DIR/ufw_cidr_blocker.conf"
    echo "  日志文件: /var/log/${SCRIPT_NAME}.log"
    echo ""
    log_info "使用方法:"
    echo "  手动运行: sudo $INSTALL_DIR/$SCRIPT_NAME"
    echo "  查看日志: sudo tail -f /var/log/${SCRIPT_NAME}.log"
    echo "  查看UFW状态: sudo ufw status numbered"
    echo "  编辑配置: sudo nano $INSTALL_DIR/ufw_cidr_blocker.conf"
    echo ""
    log_info "定时任务:"
    echo "  已设置为每周星期一早上3点自动更新规则"
    echo "  查看定时任务: sudo crontab -l"
    echo "  编辑定时任务: sudo crontab -e"
    echo ""
    log_info "默认配置:"
    echo "  阻止目标: 中国 (cn)"
    echo "  阻止端口: 53 (DNS)"
    echo "  阻止协议: TCP, UDP"
    echo "  阻止ICMP: 是"
    echo ""
    log_warn "重要提醒:"
    echo "  1. 请检查配置文件并根据需要修改阻止目标"
    echo "  2. 建议先备份现有UFW规则: sudo ufw status numbered > ufw_backup.txt"
    echo "  3. 首次运行后请测试网络连接是否正常"
    echo ""
    log_info "项目地址: $REPO_URL"
    echo ""
}

# 显示安装进度
show_progress() {
    echo ""
    echo "=========================================="
    echo "    UFW Country Blocker 一键安装程序"
    echo "=========================================="
    echo ""
    log_info "开始安装 UFW Country Blocker..."
    echo ""
}

# 主函数
main() {
    show_progress
    
    # 检查权限
    check_root
    
    # 检查网络
    check_network
    
    # 检查依赖
    check_dependencies
    
    # 创建临时目录
    create_temp_dir
    
    # 下载文件
    download_files
    
    # 安装脚本
    install_script
    
    # 创建日志目录
    create_log_dir
    
    # 启用UFW
    enable_ufw
    
    # 设置定时任务
    setup_cron
    
    # 测试脚本
    test_script
    
    # 清理临时文件
    cleanup
    
    # 显示使用说明
    show_usage
}

# 错误处理
trap 'log_error "安装过程中发生错误，请检查日志"; cleanup; exit 1' ERR

# 运行主函数
main "$@" 