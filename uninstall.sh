#!/bin/bash

# UFW CIDR Blocker 卸载脚本
# 完全卸载UFW CIDR Blocker及其所有相关文件

set -e

# 配置变量
SCRIPT_NAME="ufw_cidr_blocker"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="/usr/local/bin/${SCRIPT_NAME}.conf"
LOG_FILE="/var/log/${SCRIPT_NAME}.log"
LOCK_FILE="/var/run/${SCRIPT_NAME}.lock"
TEMP_DIR="/tmp/${SCRIPT_NAME}"
RULE_COMMENT_PREFIX="AUTO_BLOCK_CIDR"

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

# 删除UFW规则
remove_ufw_rules() {
    log "开始删除UFW自动生成规则..."
    
    # 获取所有带有特定注释的规则编号
    local rule_numbers=$(ufw status numbered | grep "$RULE_COMMENT_PREFIX" | awk -F'[][]' '{print $2}' | sort -nr)
    
    if [ -n "$rule_numbers" ]; then
        log "找到 $(echo "$rule_numbers" | wc -l) 条自动生成的规则"
        for rule_num in $rule_numbers; do
            log "删除规则 #$rule_num"
            echo "y" | ufw delete $rule_num > /dev/null 2>&1 || log "警告: 无法删除规则 #$rule_num"
        done
        log "已删除所有自动生成的UFW规则"
    else
        log "没有找到需要删除的自动生成规则"
    fi
    
    # 重载防火墙
    log "重载防火墙规则..."
    ufw reload
    log "防火墙规则重载完成"
}

# 删除系统文件
remove_system_files() {
    log "删除系统文件..."
    
    # 删除主脚本
    if [ -f "/usr/local/bin/${SCRIPT_NAME}" ]; then
        rm -f "/usr/local/bin/${SCRIPT_NAME}"
        log "已删除主脚本: /usr/local/bin/${SCRIPT_NAME}"
    else
        log "主脚本不存在: /usr/local/bin/${SCRIPT_NAME}"
    fi
    
    # 删除配置文件
    if [ -f "$CONFIG_FILE" ]; then
        rm -f "$CONFIG_FILE"
        log "已删除配置文件: $CONFIG_FILE"
    else
        log "配置文件不存在: $CONFIG_FILE"
    fi
    
    # 删除日志文件
    if [ -f "$LOG_FILE" ]; then
        rm -f "$LOG_FILE"
        log "已删除日志文件: $LOG_FILE"
    else
        log "日志文件不存在: $LOG_FILE"
    fi
    
    # 删除锁文件
    if [ -f "$LOCK_FILE" ]; then
        rm -f "$LOCK_FILE"
        log "已删除锁文件: $LOCK_FILE"
    else
        log "锁文件不存在: $LOCK_FILE"
    fi
    
    # 删除临时目录
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        log "已删除临时目录: $TEMP_DIR"
    else
        log "临时目录不存在: $TEMP_DIR"
    fi
}

# 删除systemd服务文件（如果存在）
remove_systemd_service() {
    log "检查并删除systemd服务文件..."
    
    local service_file="/etc/systemd/system/${SCRIPT_NAME}.service"
    local timer_file="/etc/systemd/system/${SCRIPT_NAME}.timer"
    
    # 停止并禁用服务
    if systemctl list-unit-files | grep -q "${SCRIPT_NAME}.service"; then
        log "停止并禁用服务: ${SCRIPT_NAME}.service"
        systemctl stop "${SCRIPT_NAME}.service" 2>/dev/null || true
        systemctl disable "${SCRIPT_NAME}.service" 2>/dev/null || true
    fi
    
    if systemctl list-unit-files | grep -q "${SCRIPT_NAME}.timer"; then
        log "停止并禁用定时器: ${SCRIPT_NAME}.timer"
        systemctl stop "${SCRIPT_NAME}.timer" 2>/dev/null || true
        systemctl disable "${SCRIPT_NAME}.timer" 2>/dev/null || true
    fi
    
    # 删除服务文件
    if [ -f "$service_file" ]; then
        rm -f "$service_file"
        log "已删除服务文件: $service_file"
    fi
    
    if [ -f "$timer_file" ]; then
        rm -f "$timer_file"
        log "已删除定时器文件: $timer_file"
    fi
    
    # 重新加载systemd
    systemctl daemon-reload
    log "已重新加载systemd"
}

# 删除cron任务（如果存在）
remove_cron_jobs() {
    log "检查并删除cron任务..."
    
    # 检查当前用户的cron任务
    if crontab -l 2>/dev/null | grep -q "$SCRIPT_NAME"; then
        log "删除当前用户的cron任务"
        crontab -l 2>/dev/null | grep -v "$SCRIPT_NAME" | crontab -
    fi
    
    # 检查root用户的cron任务
    if crontab -l -u root 2>/dev/null | grep -q "$SCRIPT_NAME"; then
        log "删除root用户的cron任务"
        crontab -l -u root 2>/dev/null | grep -v "$SCRIPT_NAME" | crontab -u root -
    fi
    
    # 检查系统cron文件
    local cron_files=("/etc/cron.d/${SCRIPT_NAME}" "/etc/cron.daily/${SCRIPT_NAME}" "/etc/cron.hourly/${SCRIPT_NAME}")
    for cron_file in "${cron_files[@]}"; do
        if [ -f "$cron_file" ]; then
            rm -f "$cron_file"
            log "已删除cron文件: $cron_file"
        fi
    done
}

# 清理日志轮转配置（如果存在）
remove_logrotate_config() {
    log "检查并删除logrotate配置..."
    
    local logrotate_file="/etc/logrotate.d/${SCRIPT_NAME}"
    if [ -f "$logrotate_file" ]; then
        rm -f "$logrotate_file"
        log "已删除logrotate配置: $logrotate_file"
    fi
}

# 显示卸载摘要
show_uninstall_summary() {
    log "=== 卸载摘要 ==="
    log "已删除的文件和目录:"
    log "  - 主脚本: /usr/local/bin/${SCRIPT_NAME}"
    log "  - 配置文件: $CONFIG_FILE"
    log "  - 日志文件: $LOG_FILE"
    log "  - 锁文件: $LOCK_FILE"
    log "  - 临时目录: $TEMP_DIR"
    log "  - systemd服务文件（如果存在）"
    log "  - cron任务（如果存在）"
    log "  - logrotate配置（如果存在）"
    log ""
    log "已清理的UFW规则:"
    log "  - 所有带有前缀 '$RULE_COMMENT_PREFIX' 的自动生成规则"
    log ""
    log "UFW CIDR Blocker 已完全卸载"
}

# 确认卸载
confirm_uninstall() {
    echo "警告: 此操作将完全卸载UFW CIDR Blocker"
    echo "将删除以下内容:"
    echo "  - 主脚本文件"
    echo "  - 配置文件"
    echo "  - 日志文件"
    echo "  - 所有自动生成的UFW规则"
    echo "  - systemd服务（如果存在）"
    echo "  - cron任务（如果存在）"
    echo ""
    read -p "确定要继续卸载吗? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "用户取消卸载操作"
        exit 0
    fi
}

# 主函数
main() {
    log "开始卸载UFW CIDR Blocker"
    
    # 检查权限
    check_root
    
    # 确认卸载
    confirm_uninstall
    
    # 删除UFW规则
    remove_ufw_rules
    
    # 删除systemd服务
    remove_systemd_service
    
    # 删除cron任务
    remove_cron_jobs
    
    # 删除logrotate配置
    remove_logrotate_config
    
    # 删除系统文件
    remove_system_files
    
    # 显示卸载摘要
    show_uninstall_summary
    
    log "卸载完成"
}

# 运行主函数
main "$@" 