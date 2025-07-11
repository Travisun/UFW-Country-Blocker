#!/bin/bash

# 配置
INSTALL_DIR="/usr/local/bin"
SYSTEMD_DIR="/etc/systemd/system"
CONFIG_DIR="/etc/fireset"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] 警告:${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] 错误:${NC} $1"
    exit 1
}

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    error "请以 root 权限运行此脚本"
fi

# 停止并禁用服务
stop_service() {
    log "停止并禁用 Fireset 服务..."
    systemctl stop fireset.timer 2>/dev/null || warn "停止 fireset.timer 失败"
    systemctl stop fireset.service 2>/dev/null || warn "停止 fireset.service 失败"
    systemctl disable fireset.timer 2>/dev/null || warn "禁用 fireset.timer 失败"
}

# 备份 ipset 规则
backup_ipsets() {
    local backup_file="/etc/fireset.backup.$(date +%Y%m%d_%H%M%S).conf"
    log "备份现有 ipset 规则到 $backup_file..."
    
    # 获取所有 blacklist_ 开头的 ipset
    local ipsets=$(ipset list -n | grep "^blacklist_")
    
    if [ -n "$ipsets" ]; then
        for ipset in $ipsets; do
            ipset save "$ipset" >> "$backup_file"
        done
        log "ipset 规则已备份到: $backup_file"
    else
        warn "未找到任何 blacklist_ ipset 规则"
    fi
}

# 删除文件
remove_files() {
    log "删除 Fireset 文件..."
    
    # 删除主程序
    rm -f "$INSTALL_DIR/fireset.sh" || warn "无法删除 fireset.sh"
    
    # 删除 systemd 服务文件
    rm -f "$SYSTEMD_DIR/fireset.service" || warn "无法删除 fireset.service"
    rm -f "$SYSTEMD_DIR/fireset.timer" || warn "无法删除 fireset.timer"
    
    # 删除配置文件（保留备份）
    if [ -f "$CONFIG_DIR/fireset.conf" ]; then
        mv "$CONFIG_DIR/fireset.conf" "$CONFIG_DIR/fireset.conf.old" || warn "无法备份配置文件"
        log "原配置文件已备份为: $CONFIG_DIR/fireset.conf.old"
    fi
}

# 重新加载 systemd
reload_systemd() {
    log "重新加载 systemd 配置..."
    systemctl daemon-reload || warn "重新加载 systemd 配置失败"
}

# 主卸载流程
main() {
    log "开始卸载 Fireset..."
    
    # 备份现有 ipset 规则
    backup_ipsets
    
    # 停止服务
    stop_service
    
    # 删除文件
    remove_files
    
    # 重新加载 systemd
    reload_systemd
    
    log "Fireset 已卸载完成！"
    log "注意：现有的 ipset 规则未被删除，可以在以下位置找到备份："
    log "- ipset 规则备份：/etc/fireset.backup.*.conf"
    log "- 配置文件备份：$CONFIG_DIR/fireset.conf.old"
}

# 运行主程序
main 