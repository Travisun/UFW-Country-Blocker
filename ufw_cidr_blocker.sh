#!/bin/bash

# UFW CIDR Blocker Script
# 自动根据CIDR列表更新UFW防火墙规则
# 支持IPv4和IPv6 CIDR列表

set -e

# 配置变量
SCRIPT_NAME="ufw_cidr_blocker"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/ufw_cidr_blocker.conf"

# 默认配置
LOG_FILE="/var/log/${SCRIPT_NAME}.log"
LOCK_FILE="/var/run/${SCRIPT_NAME}.lock"
TEMP_DIR="/tmp/${SCRIPT_NAME}"
RULE_COMMENT_PREFIX="AUTO_BLOCK_CIDR"
DOWNLOAD_TIMEOUT=30
MAX_RETRIES=3
RETRY_DELAY=5
DEBUG_MODE=false

# 默认CIDR列表URL
IPV4_URLS=("https://raw.githubusercontent.com/Travisun/Latest-Country-IP-List/refs/heads/main/data/cidr_lists/cn_ipv4.txt")
IPV6_URLS=("https://raw.githubusercontent.com/Travisun/Latest-Country-IP-List/refs/heads/main/data/cidr_lists/cn_ipv6.txt")

# 默认防火墙规则配置
BLOCK_PORTS=("53")
BLOCK_PROTOCOLS=("tcp" "udp")
BLOCK_ICMP=true
BLOCK_IPV6_ICMP=true

# 加载配置文件
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        log "加载配置文件: $CONFIG_FILE"
        source "$CONFIG_FILE"
    else
        log "配置文件不存在，使用默认配置: $CONFIG_FILE"
    fi
}

# 日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# 错误处理函数
error_exit() {
    log "ERROR: $1"
    exit 1
}

# 清理函数
cleanup() {
    if [ -f "$LOCK_FILE" ]; then
        rm -f "$LOCK_FILE"
    fi
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

# 设置信号处理
trap cleanup EXIT INT TERM

# 检查是否以root权限运行
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "此脚本需要root权限运行"
    fi
}

# 检查UFW是否启用
check_ufw() {
    if ! ufw status | grep -q "Status: active"; then
        error_exit "UFW防火墙未启用"
    fi
}

# 创建锁文件防止重复运行
create_lock() {
    if [ -f "$LOCK_FILE" ]; then
        error_exit "脚本已在运行中，锁文件存在: $LOCK_FILE"
    fi
    echo $$ > "$LOCK_FILE"
}

# 下载CIDR列表
download_cidr_list() {
    local url="$1"
    local temp_file="$2"
    local retry_count=0
    
    log "下载CIDR列表: $url"
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if curl -s -f --connect-timeout "$DOWNLOAD_TIMEOUT" -o "$temp_file" "$url"; then
            if [ -s "$temp_file" ]; then
                log "成功下载CIDR列表，共 $(wc -l < "$temp_file") 行"
                return 0
            else
                log "警告: 下载的CIDR列表为空: $url"
                return 1
            fi
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $MAX_RETRIES ]; then
                log "下载失败，${RETRY_DELAY}秒后重试 (${retry_count}/${MAX_RETRIES}): $url"
                sleep "$RETRY_DELAY"
            else
                error_exit "无法下载CIDR列表，已重试${MAX_RETRIES}次: $url"
            fi
        fi
    done
}

# 下载多个CIDR列表并合并
download_and_merge_cidr_lists() {
    local urls=("$@")
    local merged_file="$1"
    local temp_files=()
    
    # 创建临时文件列表
    for i in "${!urls[@]}"; do
        temp_files+=("${TEMP_DIR}/cidr_${i}.txt")
    done
    
    # 下载所有列表
    for i in "${!urls[@]}"; do
        if download_cidr_list "${urls[$i]}" "${temp_files[$i]}"; then
            # 合并到主文件
            cat "${temp_files[$i]}" >> "$merged_file"
        fi
    done
    
    # 清理临时文件
    for temp_file in "${temp_files[@]}"; do
        rm -f "$temp_file"
    done
    
    # 去重并排序
    if [ -s "$merged_file" ]; then
        sort -u "$merged_file" -o "$merged_file"
        log "合并后的CIDR列表共 $(wc -l < "$merged_file") 行"
    fi
}

# 验证CIDR格式
validate_cidr() {
    local cidr="$1"
    
    # 检查IPv4 CIDR格式
    if echo "$cidr" | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$' > /dev/null; then
        return 0
    fi
    
    # 检查IPv6 CIDR格式
    if echo "$cidr" | grep -E '^([0-9a-fA-F:]+::?[0-9a-fA-F:]*[0-9a-fA-F]+|[0-9a-fA-F:]+)/[0-9]{1,3}$' > /dev/null; then
        return 0
    fi
    
    return 1
}

# 删除旧规则
remove_old_rules() {
    log "删除旧的自动生成规则..."
    
    # 获取所有带有特定注释的规则编号
    local rule_numbers=$(ufw status numbered | grep "$RULE_COMMENT_PREFIX" | awk -F'[][]' '{print $2}' | sort -nr)
    
    if [ -n "$rule_numbers" ]; then
        for rule_num in $rule_numbers; do
            log "删除规则 #$rule_num"
            echo "y" | ufw delete $rule_num > /dev/null 2>&1 || true
        done
        log "已删除 $(echo "$rule_numbers" | wc -l) 条旧规则"
    else
        log "没有找到需要删除的旧规则"
    fi
}

# 添加新规则
add_new_rules() {
    local cidr_file="$1"
    local rule_count=0
    
    log "添加新的防火墙规则..."
    
    while IFS= read -r line; do
        # 跳过空行和注释行
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # 清理行内容
        local cidr=$(echo "$line" | xargs)
        
        # 验证CIDR格式
        if ! validate_cidr "$cidr"; then
            log "警告: 跳过无效的CIDR格式: $cidr"
            continue
        fi
        
        # 添加UFW规则
        local comment="${RULE_COMMENT_PREFIX}_$(date +%s)_${rule_count}"
        
        # 为每个端口和协议添加规则
        for port in "${BLOCK_PORTS[@]}"; do
            for proto in "${BLOCK_PROTOCOLS[@]}"; do
                if ufw deny from "$cidr" to any port "$port" proto "$proto" comment "$comment" > /dev/null 2>&1; then
                    log "已添加规则: 阻止 $cidr $proto $port端口"
                    ((rule_count++))
                else
                    log "警告: 无法添加 $proto $port 规则: $cidr"
                fi
            done
        done
        
        # 阻止ICMP (ping) - 仅对IPv4
        if [ "$BLOCK_ICMP" = true ] && ! echo "$cidr" | grep -q ":"; then
            if ufw deny from "$cidr" to any proto icmp comment "$comment" > /dev/null 2>&1; then
                log "已添加规则: 阻止 $cidr ICMP (ping)"
                ((rule_count++))
            else
                log "警告: 无法添加ICMP规则: $cidr"
            fi
        fi
        
        # 阻止IPv6 ICMP (ping) - 仅对IPv6
        if [ "$BLOCK_IPV6_ICMP" = true ] && echo "$cidr" | grep -q ":"; then
            if ufw deny from "$cidr" to any proto ipv6-icmp comment "$comment" > /dev/null 2>&1; then
                log "已添加规则: 阻止 $cidr IPv6-ICMP (ping)"
                ((rule_count++))
            else
                log "警告: 无法添加IPv6-ICMP规则: $cidr"
            fi
        fi
        
    done < "$cidr_file"
    
    log "总共添加了 $rule_count 条新规则"
}

# 重载防火墙
reload_firewall() {
    log "重载防火墙规则..."
    ufw reload
    log "防火墙规则重载完成"
}

# 主函数
main() {
    log "开始执行UFW CIDR阻止脚本"
    
    # 加载配置文件
    load_config
    
    # 检查权限和UFW状态
    check_root
    check_ufw
    
    # 创建锁文件
    create_lock
    
    # 创建临时目录
    mkdir -p "$TEMP_DIR"
    
    # 删除旧规则
    remove_old_rules
    
    # 处理IPv4 CIDR列表
    if [ ${#IPV4_URLS[@]} -gt 0 ]; then
        local ipv4_file="$TEMP_DIR/ipv4_cidr.txt"
        touch "$ipv4_file"
        download_and_merge_cidr_lists "$ipv4_file" "${IPV4_URLS[@]}"
        if [ -s "$ipv4_file" ]; then
            add_new_rules "$ipv4_file"
        else
            log "警告: IPv4 CIDR列表为空"
        fi
    fi
    
    # 处理IPv6 CIDR列表
    if [ ${#IPV6_URLS[@]} -gt 0 ]; then
        local ipv6_file="$TEMP_DIR/ipv6_cidr.txt"
        touch "$ipv6_file"
        download_and_merge_cidr_lists "$ipv6_file" "${IPV6_URLS[@]}"
        if [ -s "$ipv6_file" ]; then
            add_new_rules "$ipv6_file"
        else
            log "警告: IPv6 CIDR列表为空"
        fi
    fi
    
    # 重载防火墙
    reload_firewall
    
    log "脚本执行完成"
}

# 运行主函数
main "$@" 