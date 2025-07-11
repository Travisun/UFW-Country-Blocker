#!/bin/bash

# UFW CIDR Blocker 安装脚本
# 安装UFW CIDR Blocker到系统

set -e

# 配置变量
SCRIPT_NAME="ufw_cidr_blocker"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/usr/local/bin"
CONFIG_FILE="$INSTALL_DIR/${SCRIPT_NAME}.conf"
SERVICE_FILE="/etc/systemd/system/${SCRIPT_NAME}.service"
TIMER_FILE="/etc/systemd/system/${SCRIPT_NAME}.timer"

# 日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 错误处理函数
error_exit() {
    log "ERROR: $1"
    exit 1
}

# 检查是否以root权限运行
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "此脚本需要root权限运行"
    fi
}

# 检查系统要求
check_requirements() {
    log "检查系统要求..."
    
    # 检查UFW是否安装
    if ! command -v ufw >/dev/null 2>&1; then
        error_exit "UFW防火墙未安装，请先安装UFW: apt install ufw"
    fi
    
    # 检查UFW是否启用
    if ! ufw status | grep -q "Status: active"; then
        log "警告: UFW防火墙未启用，建议启用UFW"
        read -p "是否现在启用UFW? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ufw --force enable
            log "UFW已启用"
        fi
    fi
    
    # 检查curl是否安装
    if ! command -v curl >/dev/null 2>&1; then
        error_exit "curl未安装，请先安装curl: apt install curl"
    fi
    
    log "系统要求检查完成"
}

# 备份现有文件
backup_existing_files() {
    log "备份现有文件..."
    
    local backup_dir="/tmp/${SCRIPT_NAME}_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    if [ -f "$INSTALL_DIR/${SCRIPT_NAME}" ]; then
        cp "$INSTALL_DIR/${SCRIPT_NAME}" "$backup_dir/"
        log "已备份主脚本到: $backup_dir/${SCRIPT_NAME}"
    fi
    
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "$backup_dir/"
        log "已备份配置文件到: $backup_dir/${SCRIPT_NAME}.conf"
    fi
    
    if [ -f "$SERVICE_FILE" ]; then
        cp "$SERVICE_FILE" "$backup_dir/"
        log "已备份服务文件到: $backup_dir/${SCRIPT_NAME}.service"
    fi
    
    if [ -f "$TIMER_FILE" ]; then
        cp "$TIMER_FILE" "$backup_dir/"
        log "已备份定时器文件到: $backup_dir/${SCRIPT_NAME}.timer"
    fi
    
    echo "$backup_dir" > /tmp/${SCRIPT_NAME}_backup_path
    log "备份完成，备份目录: $backup_dir"
}

# 安装主脚本
install_main_script() {
    log "安装主脚本..."
    
    # 复制主脚本
    cp "$SCRIPT_DIR/${SCRIPT_NAME}.sh" "$INSTALL_DIR/${SCRIPT_NAME}"
    chmod +x "$INSTALL_DIR/${SCRIPT_NAME}"
    log "主脚本已安装到: $INSTALL_DIR/${SCRIPT_NAME}"
}

# 安装配置文件
install_config_file() {
    log "安装配置文件..."
    
    if [ -f "$SCRIPT_DIR/${SCRIPT_NAME}.conf" ]; then
        cp "$SCRIPT_DIR/${SCRIPT_NAME}.conf" "$CONFIG_FILE"
        log "配置文件已安装到: $CONFIG_FILE"
    else
        error_exit "配置文件不存在: $SCRIPT_DIR/${SCRIPT_NAME}.conf"
    fi
}

# 安装systemd服务
install_systemd_service() {
    log "安装systemd服务..."
    
    # 复制服务文件
    if [ -f "$SCRIPT_DIR/${SCRIPT_NAME}.service" ]; then
        cp "$SCRIPT_DIR/${SCRIPT_NAME}.service" "$SERVICE_FILE"
        log "服务文件已安装到: $SERVICE_FILE"
    else
        error_exit "服务文件不存在: $SCRIPT_DIR/${SCRIPT_NAME}.service"
    fi
    
    # 复制定时器文件
    if [ -f "$SCRIPT_DIR/${SCRIPT_NAME}.timer" ]; then
        cp "$SCRIPT_DIR/${SCRIPT_NAME}.timer" "$TIMER_FILE"
        log "定时器文件已安装到: $TIMER_FILE"
    else
        error_exit "定时器文件不存在: $SCRIPT_DIR/${SCRIPT_NAME}.timer"
    fi
    
    # 重新加载systemd
    systemctl daemon-reload
    log "systemd已重新加载"
    
    # 启用定时器
    systemctl enable "${SCRIPT_NAME}.timer"
    log "定时器已启用"
    
    # 启动定时器
    systemctl start "${SCRIPT_NAME}.timer"
    log "定时器已启动"
}

# 创建日志目录
create_log_directory() {
    log "创建日志目录..."
    
    local log_dir="/var/log"
    if [ ! -d "$log_dir" ]; then
        mkdir -p "$log_dir"
    fi
    
    # 创建日志文件
    touch "/var/log/${SCRIPT_NAME}.log"
    chmod 644 "/var/log/${SCRIPT_NAME}.log"
    log "日志文件已创建: /var/log/${SCRIPT_NAME}.log"
}

# 测试安装
test_installation() {
    log "测试安装..."
    
    # 测试主脚本
    if [ -x "$INSTALL_DIR/${SCRIPT_NAME}" ]; then
        log "主脚本权限检查通过"
    else
        error_exit "主脚本权限检查失败"
    fi
    
    # 测试配置文件
    if [ -f "$CONFIG_FILE" ]; then
        log "配置文件检查通过"
    else
        error_exit "配置文件检查失败"
    fi
    
    # 测试systemd服务
    if systemctl is-enabled "${SCRIPT_NAME}.timer" >/dev/null 2>&1; then
        log "systemd服务检查通过"
    else
        log "警告: systemd服务检查失败"
    fi
    
    log "安装测试完成"
}

# 显示安装信息
show_installation_info() {
    log "=== 安装完成 ==="
    echo ""
    echo "UFW CIDR Blocker 已成功安装"
    echo ""
    echo "安装位置:"
    echo "  - 主脚本: $INSTALL_DIR/${SCRIPT_NAME}"
    echo "  - 配置文件: $CONFIG_FILE"
    echo "  - 服务文件: $SERVICE_FILE"
    echo "  - 定时器文件: $TIMER_FILE"
    echo "  - 日志文件: /var/log/${SCRIPT_NAME}.log"
    echo ""
    echo "使用方法:"
    echo "  - 手动运行: sudo $INSTALL_DIR/${SCRIPT_NAME}"
    echo "  - 查看状态: sudo systemctl status ${SCRIPT_NAME}.timer"
    echo "  - 查看日志: sudo journalctl -u ${SCRIPT_NAME}.service"
    echo "  - 停止定时器: sudo systemctl stop ${SCRIPT_NAME}.timer"
    echo "  - 禁用定时器: sudo systemctl disable ${SCRIPT_NAME}.timer"
    echo ""
    echo "配置说明:"
    echo "  - 编辑配置文件: sudo nano $CONFIG_FILE"
    echo "  - 默认每天凌晨2点自动运行"
    echo "  - 默认阻止中国IP的DNS端口(53)"
    echo ""
    echo "卸载方法:"
    echo "  - 运行卸载脚本: sudo ./uninstall.sh"
    echo ""
}

# 询问是否安装systemd服务
ask_install_service() {
    echo "是否安装systemd服务以自动运行脚本? (推荐)"
    echo "  - 每天凌晨2点自动运行"
    echo "  - 系统启动后自动启动"
    echo "  - 支持日志记录和状态监控"
    echo ""
    read -p "安装systemd服务? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        return 1
    else
        return 0
    fi
}

# 主函数
main() {
    log "开始安装UFW CIDR Blocker"
    
    # 检查权限
    check_root
    
    # 检查系统要求
    check_requirements
    
    # 备份现有文件
    backup_existing_files
    
    # 安装主脚本
    install_main_script
    
    # 安装配置文件
    install_config_file
    
    # 创建日志目录
    create_log_directory
    
    # 询问是否安装systemd服务
    if ask_install_service; then
        install_systemd_service
    else
        log "跳过systemd服务安装"
    fi
    
    # 测试安装
    test_installation
    
    # 显示安装信息
    show_installation_info
    
    log "安装完成"
}

# 运行主函数
main "$@" 