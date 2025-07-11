#!/bin/bash

# 配置
GITHUB_REPO="Travisun/fireset"  # 请替换为实际的 GitHub 仓库
GITHUB_BRANCH="main"
TEMP_DIR="/tmp/fireset_install"
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

# 检查必要的命令
check_commands() {
    local commands=("curl" "ipset" "systemctl")
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            error "未找到必要的命令: $cmd"
        fi
    done
}

# 创建必要的目录
create_directories() {
    log "创建必要的目录..."
    mkdir -p "$TEMP_DIR" "$CONFIG_DIR" || error "无法创建目录"
}

# 下载文件
download_file() {
    local file="$1"
    local url="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}/${file}"
    log "下载 $file..."
    curl -sSL "$url" -o "$TEMP_DIR/$file" || error "无法下载 $file"
}

# 下载所需文件
download_files() {
    log "从 GitHub 下载文件..."
    local files=("fireset.sh" "fireset.service" "fireset.timer")
    for file in "${files[@]}"; do
        download_file "$file"
    done
}

# 安装文件
install_files() {
    log "安装文件到系统..."
    
    # 安装主程序
    cp "$TEMP_DIR/fireset.sh" "$INSTALL_DIR/" || error "无法复制 fireset.sh"
    chmod +x "$INSTALL_DIR/fireset.sh" || error "无法设置执行权限"
    
    # 安装 systemd 服务文件
    cp "$TEMP_DIR/fireset.service" "$SYSTEMD_DIR/" || error "无法复制 fireset.service"
    cp "$TEMP_DIR/fireset.timer" "$SYSTEMD_DIR/" || error "无法复制 fireset.timer"
    
    # 创建配置目录和文件
    touch "$CONFIG_DIR/fireset.conf" || error "无法创建配置文件"
}

# 配置 systemd 服务
setup_service() {
    log "配置 systemd 服务..."
    systemctl daemon-reload || error "无法重新加载 systemd 配置"
    systemctl enable fireset.timer || error "无法启用 fireset.timer"
    systemctl start fireset.timer || warn "无法启动 fireset.timer"
    
    # 立即运行一次更新
    log "执行首次 IP 集合更新..."
    systemctl start fireset.service || warn "首次更新失败，请检查日志"
}

# 清理临时文件
cleanup() {
    log "清理临时文件..."
    rm -rf "$TEMP_DIR"
}

# 显示安装结果
show_status() {
    log "安装完成！"
    echo "服务状态："
    systemctl status fireset.timer
    echo "下次运行时间："
    systemctl list-timers fireset.timer
}

# 主安装流程
main() {
    log "开始安装 Fireset..."
    check_commands
    create_directories
    download_files
    install_files
    setup_service
    cleanup
    show_status
    log "Fireset 安装成功！"
}

# 运行主程序
main 