#!/bin/bash

# UFW命令测试脚本
# 用于验证UFW命令的正确执行

# 日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 测试单个UFW命令
test_ufw_command() {
    local cmd="$1"
    local description="$2"
    
    log "测试$description"
    log "执行命令: $cmd"
    
    # 执行命令并捕获输出
    output=$(eval "$cmd" 2>&1)
    exit_code=$?
    
    log "输出: $output"
    log "退出代码: $exit_code"
    
    # 等待1秒让UFW处理规则
    sleep 1
    
    return $exit_code
}

# 主测试函数
main() {
    log "开始测试UFW命令..."
    
    # 测试CIDR和端口
    local test_cidr="1.1.1.1/32"
    local test_port="53"
    local test_proto="tcp"
    
    log "测试CIDR: $test_cidr"
    log "测试端口: $test_port"
    log "测试协议: $test_proto"
    
    # 测试1: 基本的deny from命令
    test_ufw_command "ufw deny from $test_cidr" "基本的deny from命令"
    
    # 测试2: deny from to port proto命令
    test_ufw_command "ufw deny from $test_cidr to any port $test_port proto $test_proto" "deny from to port proto命令"
    
    # 测试3: deny from to proto icmp命令
    test_ufw_command "ufw deny from $test_cidr to any proto icmp" "deny from to proto icmp命令"
    
    # 显示当前规则
    log "当前UFW规则:"
    ufw status numbered
}

# 运行主函数
main "$@" 