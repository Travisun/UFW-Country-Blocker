#!/bin/bash

# 测试UFW命令的简单脚本

set -e

# 日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then
    echo "此脚本需要root权限运行"
    exit 1
fi

log "开始测试UFW命令..."

# 测试CIDR
TEST_CIDR="1.1.1.1/32"
TEST_PORT="53"
TEST_PROTO="tcp"

log "测试CIDR: $TEST_CIDR"
log "测试端口: $TEST_PORT"
log "测试协议: $TEST_PROTO"

# 测试1: 基本的deny from命令
log "测试1: 基本的deny from命令"
log "执行命令: ufw deny from $TEST_CIDR"
output=$(ufw deny from "$TEST_CIDR" 2>&1)
exit_code=$?
log "输出: $output"
log "退出代码: $exit_code"

# 测试2: deny from to port proto命令
log "测试2: deny from to port proto命令"
log "执行命令: ufw deny from $TEST_CIDR to any port $TEST_PORT proto $TEST_PROTO"
output=$(ufw deny from "$TEST_CIDR" to any port "$TEST_PORT" proto "$TEST_PROTO" 2>&1)
exit_code=$?
log "输出: $output"
log "退出代码: $exit_code"

# 测试3: deny from to proto icmp命令
log "测试3: deny from to proto icmp命令"
log "执行命令: ufw deny from $TEST_CIDR to any proto icmp"
output=$(ufw deny from "$TEST_CIDR" to any proto icmp 2>&1)
exit_code=$?
log "输出: $output"
log "退出代码: $exit_code"

# 查看UFW状态
log "查看UFW状态:"
ufw status numbered

# 清理测试规则
log "清理测试规则..."
ufw status numbered | grep "$TEST_CIDR" | awk -F'[][]' '{print $2}' | sort -nr | while read rule_num; do
    if [ -n "$rule_num" ]; then
        log "删除规则 #$rule_num"
        echo "y" | ufw delete "$rule_num" > /dev/null 2>&1 || true
    fi
done

log "测试完成" 