#!/bin/bash

# UFW CIDR Blocker 测试脚本
# 用于测试和验证脚本功能

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="${SCRIPT_DIR}/ufw_cidr_blocker.sh"
CONFIG_FILE="${SCRIPT_DIR}/ufw_cidr_blocker.conf"

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查脚本文件
check_files() {
    log_info "检查脚本文件..."
    
    if [ ! -f "$MAIN_SCRIPT" ]; then
        log_error "主脚本文件不存在: $MAIN_SCRIPT"
        return 1
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "配置文件不存在: $CONFIG_FILE"
        return 1
    fi
    
    if [ ! -x "$MAIN_SCRIPT" ]; then
        log_warning "主脚本没有执行权限，正在添加..."
        chmod +x "$MAIN_SCRIPT"
    fi
    
    log_success "文件检查完成"
}

# 备份当前UFW规则
backup_ufw_rules() {
    log_info "备份当前UFW规则..."
    local backup_file="/tmp/ufw_backup_$(date +%Y%m%d_%H%M%S).txt"
    
    if ufw status numbered > "$backup_file" 2>/dev/null; then
        log_success "UFW规则已备份到: $backup_file"
        echo "$backup_file"
    else
        log_error "无法备份UFW规则"
        return 1
    fi
}

# 启用测试模式
enable_test_mode() {
    log_info "启用测试模式..."
    
    # 备份原配置
    cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"
    
    # 修改配置为测试模式
    sed -i 's/TEST_MODE=false/TEST_MODE=true/' "$CONFIG_FILE"
    sed -i 's/TEST_CIDR_LIMIT=10/TEST_CIDR_LIMIT=5/' "$CONFIG_FILE"
    
    log_success "测试模式已启用，限制处理5个CIDR"
}

# 恢复原配置
restore_config() {
    log_info "恢复原配置..."
    
    if [ -f "${CONFIG_FILE}.backup" ]; then
        mv "${CONFIG_FILE}.backup" "$CONFIG_FILE"
        log_success "配置已恢复"
    else
        log_warning "没有找到备份配置文件"
    fi
}

# 运行测试
run_test() {
    log_info "开始运行UFW CIDR阻止脚本测试..."
    
    # 检查当前UFW规则数量
    local before_rules=$(ufw status numbered | grep -c "AUTO_BLOCK_CIDR" || echo "0")
    log_info "测试前自动规则数量: $before_rules"
    
    # 运行主脚本
    if sudo "$MAIN_SCRIPT"; then
        log_success "脚本执行成功"
        
        # 检查添加的规则数量
        local after_rules=$(ufw status numbered | grep -c "AUTO_BLOCK_CIDR" || echo "0")
        local added_rules=$((after_rules - before_rules))
        
        log_info "测试后自动规则数量: $after_rules"
        log_info "新增规则数量: $added_rules"
        
        if [ $added_rules -gt 0 ]; then
            log_success "测试成功！新增了 $added_rules 条规则"
            
            # 显示新增的规则
            log_info "新增的规则:"
            ufw status numbered | grep "AUTO_BLOCK_CIDR" | tail -n $added_rules
        else
            log_warning "没有新增规则，可能存在问题"
        fi
    else
        log_error "脚本执行失败"
        return 1
    fi
}

# 清理测试
cleanup_test() {
    log_info "清理测试环境..."
    
    # 删除测试生成的规则
    local test_rules=$(ufw status numbered | grep "AUTO_BLOCK_CIDR" | awk -F'[][]' '{print $2}' | sort -nr)
    
    if [ -n "$test_rules" ]; then
        log_info "删除测试生成的规则..."
        for rule_num in $test_rules; do
            echo "y" | sudo ufw delete $rule_num > /dev/null 2>&1 || true
        done
        log_success "已删除 $(echo "$test_rules" | wc -l) 条测试规则"
    fi
    
    # 恢复配置
    restore_config
}

# 主函数
main() {
    log_info "开始UFW CIDR阻止脚本测试"
    
    # 检查文件
    check_files || exit 1
    
    # 备份UFW规则
    local backup_file=$(backup_ufw_rules) || exit 1
    
    # 启用测试模式
    enable_test_mode
    
    # 运行测试
    if run_test; then
        log_success "测试完成"
    else
        log_error "测试失败"
    fi
    
    # 清理测试
    cleanup_test
    
    log_info "测试脚本执行完成"
    log_info "原UFW规则备份在: $backup_file"
}

# 运行主函数
main "$@" 