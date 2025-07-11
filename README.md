# Fireset

Fireset 是一个用于防火墙的 IP Set 管理工具，支持按国家自动更新 IPv4 和 IPv6 地址集合。

## 功能特点

- 支持多个国家的 IP 地址集合管理
- 同时支持 IPv4 和 IPv6 地址
- 自动定期更新 IP 地址列表
- 支持与 UFW/iptables 等防火墙集成
- 使用 systemd 进行服务管理
- 支持系统重启后自动恢复规则

## 安装

```bash
sudo bash install.sh
```

## 配置

编辑 `update_ip_blacklist.sh` 文件中的 `COUNTRIES` 数组来添加或移除需要管理的国家：

```bash
declare -A COUNTRIES=(
    ["cn"]="China"
    ["ru"]="Russia"
    ["kr"]="South Korea"
    # 在此添加更多国家
)
```

## 使用方法

### 服务管理

```bash
# 查看服务状态
sudo systemctl status fireset.service

# 查看定时器状态
sudo systemctl status fireset.timer

# 立即更新 IP 列表
sudo systemctl start fireset.service

# 查看下次更新时间
sudo systemctl list-timers fireset.timer
```

### 防火墙集成

Fireset 创建的 IP 集合名称格式为：`blacklist_国家代码_IP版本`

例如：
- `blacklist_cn_ipv4`：中国 IPv4 地址集合
- `blacklist_ru_ipv6`：俄罗斯 IPv6 地址集合

可以在防火墙规则中引用这些集合：

```bash
# UFW 示例
sudo ufw deny from blacklist_cn_ipv4
sudo ufw deny from blacklist_cn_ipv6

# iptables 示例
sudo iptables -I INPUT -m set --match-set blacklist_cn_ipv4 src -j DROP
sudo ip6tables -I INPUT -m set --match-set blacklist_cn_ipv6 src -j DROP
```

## 定时更新设置

默认每天凌晨 3 点自动更新。如需修改更新时间，编辑 `/etc/systemd/system/fireset.timer` 文件。

## 许可证

MIT License 