#!/bin/bash

# 配置国家和对应的 IP 列表 URL
declare -A COUNTRIES=(
    ["cn"]="China"
    ["ru"]="Russia"
    ["kr"]="South Korea"
    # 在此添加更多国家
)

# IP 列表基础 URL
BASE_URL="https://raw.githubusercontent.com/Travisun/Latest-Country-IP-List/refs/heads/main/data/cidr_lists"

# 临时目录
TEMP_DIR="/tmp/fireset"
# ipset 配置的保存路径
IPSET_SAVE_FILE="/etc/fireset.conf"

# 日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1"
}

# 错误处理函数
handle_error() {
    log "错误: $1"
    cleanup
    exit 1
}

# 清理函数
cleanup() {
    rm -rf "$TEMP_DIR"
}

# 验证 IP 地址格式
validate_ip() {
    local ip=$1
    local type=$2

    case $type in
        "ipv4")
            [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(/[0-9]{1,2})?$ ]]
            ;;
        "ipv6")
            # 简化的 IPv6 验证，实际使用时可能需要更严格的验证
            [[ "$ip" =~ ^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}(/[0-9]{1,3})?$ ]]
            ;;
    esac
    return $?
}

# 创建和更新 ipset
update_ipset() {
    local country_code=$1
    local ip_version=$2
    local temp_file=$3
    local ipset_name="blacklist_${country_code}_${ip_version}"
    local family_option="inet"
    [[ "$ip_version" == "ipv6" ]] && family_option="inet6"

    # 检查 ipset 是否存在，不存在则创建
    if ! sudo ipset list "$ipset_name" &>/dev/null; then
        log "创建新的 ipset: $ipset_name"
        sudo ipset create "$ipset_name" hash:net family $family_option || handle_error "无法创建 ipset $ipset_name"
    else
        log "清空现有 ipset: $ipset_name"
        sudo ipset flush "$ipset_name" || handle_error "无法清空 ipset $ipset_name"
    fi

    local added_count=0
    while IFS= read -r ip; do
        if [[ -n "$ip" && ! "$ip" =~ ^# ]]; then
            if validate_ip "$ip" "$ip_version"; then
                sudo ipset add "$ipset_name" "$ip" -exist
                ((added_count++))
            else
                log "警告: 跳过无效的 IP 格式: $ip"
            fi
        fi
    done < "$temp_file"

    log "已添加 $added_count 个条目到 $ipset_name"
    
    # 保存 ipset 规则
    sudo ipset save "$ipset_name" >> "$IPSET_SAVE_FILE.tmp"
}

# 主程序
main() {
    log "开始更新 IP 集合..."

    # 创建临时目录
    mkdir -p "$TEMP_DIR" || handle_error "无法创建临时目录"
    
    # 创建新的保存文件
    : > "$IPSET_SAVE_FILE.tmp"

    # 遍历所有国家
    for country_code in "${!COUNTRIES[@]}"; do
        country_name="${COUNTRIES[$country_code]}"
        log "处理 $country_name 的 IP 列表..."

        # 处理 IPv4
        local ipv4_url="$BASE_URL/${country_code}_ipv4.txt"
        local ipv4_file="$TEMP_DIR/${country_code}_ipv4.txt"
        log "下载 IPv4 列表: $ipv4_url"
        if curl -sL "$ipv4_url" -o "$ipv4_file"; then
            if [ -s "$ipv4_file" ]; then
                update_ipset "$country_code" "ipv4" "$ipv4_file"
            else
                log "警告: ${country_name} 的 IPv4 列表为空"
            fi
        else
            log "警告: 无法下载 ${country_name} 的 IPv4 列表"
        fi

        # 处理 IPv6
        local ipv6_url="$BASE_URL/${country_code}_ipv6.txt"
        local ipv6_file="$TEMP_DIR/${country_code}_ipv6.txt"
        log "下载 IPv6 列表: $ipv6_url"
        if curl -sL "$ipv6_url" -o "$ipv6_file"; then
            if [ -s "$ipv6_file" ]; then
                update_ipset "$country_code" "ipv6" "$ipv6_file"
            else
                log "警告: ${country_name} 的 IPv6 列表为空"
            fi
        else
            log "警告: 无法下载 ${country_name} 的 IPv6 列表"
        fi
    done

    # 替换旧的保存文件
    mv "$IPSET_SAVE_FILE.tmp" "$IPSET_SAVE_FILE" || handle_error "无法更新 ipset 保存文件"

    # 清理临时文件
    cleanup
    log "IP 集合更新完成"
}

# 运行主程序
main 