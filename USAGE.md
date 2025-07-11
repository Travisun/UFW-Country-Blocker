# UFW CIDR Blocker 使用说明

## 快速开始

### 安装
```bash
# GitHub一键安装（推荐）
curl -fsSL https://raw.githubusercontent.com/Travisun/UFW-Country-Blocker/main/install_github.sh | sudo bash

# 或本地安装
git clone https://github.com/Travisun/UFW-Country-Blocker.git
cd UFW-Country-Blocker
sudo bash install.sh
```

### 使用
```bash
# 手动运行
sudo /usr/local/bin/ufw_cidr_blocker

# 查看状态
sudo systemctl status ufw_cidr_blocker.timer

# 查看日志
sudo tail -f /var/log/ufw_cidr_blocker.log
```

### 卸载
```bash
# GitHub卸载
curl -fsSL https://raw.githubusercontent.com/Travisun/UFW-Country-Blocker/main/uninstall_github.sh | sudo bash

# 或本地卸载
sudo bash uninstall.sh
```

## 配置

编辑配置文件：
```bash
sudo nano /usr/local/bin/ufw_cidr_blocker.conf
```

### 阻止其他国家
```bash
# 阻止美国IP
IPV4_URLS=("https://raw.githubusercontent.com/Travisun/Latest-Country-IP-List/refs/heads/main/data/cidr_lists/us_ipv4.txt")

# 阻止多个国家
IPV4_URLS=(
    "https://raw.githubusercontent.com/Travisun/Latest-Country-IP-List/refs/heads/main/data/cidr_lists/cn_ipv4.txt"
    "https://raw.githubusercontent.com/Travisun/Latest-Country-IP-List/refs/heads/main/data/cidr_lists/ru_ipv4.txt"
)
```

### 阻止其他端口
```bash
# 阻止HTTP和HTTPS
BLOCK_PORTS=("80" "443" "53")
```

## 故障排除

### 测试模式
```bash
# 编辑配置文件启用测试模式
TEST_MODE=true
TEST_CIDR_LIMIT=5
```

### 查看UFW规则
```bash
# 查看所有规则
sudo ufw status numbered

# 查看自动生成的规则
sudo ufw status numbered | grep "AUTO_BLOCK_CIDR"
```

### 备份规则
```bash
# 备份现有UFW规则
sudo ufw status numbered > ufw_backup_$(date +%Y%m%d).txt
```

## 默认配置

- **阻止目标**: 中国IP
- **阻止端口**: 53 (DNS)
- **阻止协议**: TCP, UDP
- **自动更新**: 每天凌晨2点
- **日志文件**: `/var/log/ufw_cidr_blocker.log`

## 支持的国家代码

- `cn` - 中国
- `us` - 美国
- `ru` - 俄罗斯
- `jp` - 日本
- `kr` - 韩国
- `ae` - 阿联酋
- 更多国家请查看: https://github.com/Travisun/Latest-Country-IP-List 