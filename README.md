# UFW Country Blocker

一个基于UFW防火墙的自动化国家/地区IP阻止工具，支持IPv4和IPv6 CIDR列表，可自动更新防火墙规则以阻止特定国家或地区的网络访问。

## 🚀 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/Travisun/UFW-Country-Blocker/main/install.sh | sudo bash
```

## 功能特性

- 🔒 **自动CIDR列表更新**: 从GitHub等源自动下载最新的国家/地区IP列表
- 🌐 **IPv4/IPv6支持**: 同时支持IPv4和IPv6地址段阻止
- 🛡️ **多端口阻止**: 可配置阻止多个端口（默认阻止DNS端口53）
- 📊 **协议控制**: 支持TCP、UDP协议阻止
- 🚫 **ICMP阻止**: 可阻止ping请求（IPv4和IPv6）
- ⏰ **定时任务**: 支持cron定时自动更新规则
- 📝 **完整日志**: 详细的操作日志记录
- 🔄 **规则管理**: 自动清理旧规则并应用新规则
- ⚙️ **灵活配置**: 通过配置文件自定义所有行为

## 系统要求

- Ubuntu/Debian系统
- UFW防火墙已启用
- root权限
- curl（用于下载CIDR列表）
- cron（用于定时任务）

## 快速开始

### 方法一：一键安装（推荐）

```bash
# 下载并运行一键安装脚本
curl -fsSL https://raw.githubusercontent.com/Travisun/UFW-Country-Blocker/main/install.sh | sudo bash
```

或者：

```bash
# 下载安装脚本
wget https://raw.githubusercontent.com/Travisun/UFW-Country-Blocker/main/install.sh

# 运行安装脚本
sudo bash install.sh
```

一键安装脚本将自动：
- 从GitHub下载最新版本的文件
- 检查并安装系统依赖（UFW、curl、cron）
- 安装主程序到 `/usr/local/bin/`
- 创建日志文件
- 启用并配置UFW防火墙
- 设置每周星期一早上3点自动更新的定时任务
- 提供完整的安装后使用说明

### 方法二：手动安装

如果您想手动安装，请确保您有以下文件：
- `install_ufw_blocker.sh` - 安装脚本
- `ufw_cidr_blocker.sh` - 主程序脚本
- `ufw_cidr_blocker.conf` - 配置文件

然后运行：

```bash
sudo chmod +x install_ufw_blocker.sh
sudo ./install_ufw_blocker.sh
```

### 配置阻止目标

安装完成后，编辑配置文件：

```bash
sudo nano /usr/local/bin/ufw_cidr_blocker.conf
```

## 配置说明

### 基本配置

```bash
# CIDR列表URL配置
IPV4_URLS=(
    "https://raw.githubusercontent.com/Travisun/Latest-Country-IP-List/refs/heads/main/data/cidr_lists/ae_ipv4.txt"
    # 添加更多IPv4列表
)

IPV6_URLS=(
    "https://raw.githubusercontent.com/Travisun/Latest-Country-IP-List/refs/heads/main/data/cidr_lists/ae_ipv6.txt"
    # 添加更多IPv6列表
)
```

### 防火墙规则配置

```bash
# 要阻止的端口列表
BLOCK_PORTS=(
    "53"    # DNS端口
    "80"    # HTTP端口
    "443"   # HTTPS端口
)

# 要阻止的协议
BLOCK_PROTOCOLS=(
    "tcp"   # TCP协议
    "udp"   # UDP协议
)

# 是否阻止ICMP (ping)
BLOCK_ICMP=true
BLOCK_IPV6_ICMP=true
```

### 高级配置

```bash
# 日志配置
LOG_LEVEL="INFO"  # DEBUG, INFO, WARN, ERROR
LOG_FILE="/var/log/ufw_cidr_blocker.log"

# 网络超时和重试
DOWNLOAD_TIMEOUT=30
MAX_RETRIES=3
RETRY_DELAY=5

# 调试模式
DEBUG_MODE=false
```

## 使用方法

### 手动运行

```bash
# 立即执行一次规则更新
sudo ufw_cidr_blocker

# 查看执行日志
sudo tail -f /var/log/ufw_cidr_blocker.log
```

### 查看防火墙状态

```bash
# 查看所有UFW规则
sudo ufw status numbered

# 查看阻止的规则
sudo ufw status numbered | grep AUTO_BLOCK_CIDR
```

### 管理定时任务

```bash
# 查看当前定时任务
sudo crontab -l

# 编辑定时任务
sudo crontab -e

# 删除定时任务
sudo crontab -r
```

**默认定时任务**: 每周星期一早上3点自动更新规则

## 支持的CIDR列表源

项目默认使用 [Travisun/Latest-Country-IP-List](https://github.com/Travisun/Latest-Country-IP-List) 作为CIDR列表源。

### 可用的国家/地区代码

- `ae` - 阿联酋
- `cn` - 中国
- `us` - 美国
- `ru` - 俄罗斯
- `kr` - 韩国
- `jp` - 日本
- 等等...

### 自定义CIDR列表

您可以添加任何提供CIDR列表的URL：

```bash
IPV4_URLS=(
    "https://raw.githubusercontent.com/Travisun/Latest-Country-IP-List/refs/heads/main/data/cidr_lists/ae_ipv4.txt"
    "https://your-custom-source.com/custom_ipv4_list.txt"
    "https://another-source.com/blocklist.txt"
)
```

## 日志和监控

### 日志文件位置

- 主日志: `/var/log/ufw_cidr_blocker.log`
- 定时任务日志: 通过cron重定向到主日志文件

### 日志级别

- `DEBUG` - 详细调试信息
- `INFO` - 一般信息（默认）
- `WARN` - 警告信息
- `ERROR` - 错误信息

### 监控示例

```bash
# 实时查看日志
sudo tail -f /var/log/ufw_cidr_blocker.log

# 查看最近的错误
sudo grep "ERROR" /var/log/ufw_cidr_blocker.log

# 查看规则更新统计
sudo grep "添加了.*条新规则" /var/log/ufw_cidr_blocker.log
```

## 故障排除

### 常见问题

1. **权限错误**
   ```bash
   # 确保以root权限运行
   sudo ufw_cidr_blocker
   ```

2. **UFW未启用**
   ```bash
   # 启用UFW
   sudo ufw enable
   ```

3. **网络连接问题**
   ```bash
   # 检查网络连接
   curl -I https://raw.githubusercontent.com/Travisun/Latest-Country-IP-List/refs/heads/main/data/cidr_lists/ae_ipv4.txt
   ```

4. **锁文件问题**
   ```bash
   # 删除锁文件（如果脚本异常退出）
   sudo rm -f /var/run/ufw_cidr_blocker.lock
   ```

### 调试模式

启用调试模式获取更详细的信息：

```bash
# 编辑配置文件
sudo nano /usr/local/bin/ufw_cidr_blocker.conf

# 设置调试模式
DEBUG_MODE=true
```

## 安全注意事项

1. **备份现有规则**: 在首次运行前备份现有UFW规则
   ```bash
   sudo ufw status numbered > ufw_backup.txt
   ```

2. **测试环境**: 建议先在测试环境中验证配置

3. **监控影响**: 运行后监控网络连接是否正常

4. **定期检查**: 定期检查日志确保脚本正常运行

## 卸载

如需卸载此工具：

```bash
# 删除脚本文件
sudo rm -f /usr/local/bin/ufw_cidr_blocker

# 删除配置文件
sudo rm -f /usr/local/bin/ufw_cidr_blocker.conf

# 删除日志文件
sudo rm -f /var/log/ufw_cidr_blocker.log

# 删除锁文件
sudo rm -f /var/run/ufw_cidr_blocker.lock

# 删除定时任务
sudo crontab -e
# 手动删除相关cron条目

# 清理UFW规则（可选）
sudo ufw status numbered | grep AUTO_BLOCK_CIDR | awk -F'[][]' '{print $2}' | sort -nr | xargs -I {} echo "y" | sudo ufw delete {}
```

## 许可证

本项目采用MIT许可证。

## 贡献

欢迎提交Issue和Pull Request来改进这个项目。

## 更新日志

### v1.0.0
- 初始版本发布
- 支持IPv4/IPv6 CIDR列表
- 自动规则管理
- 定时任务支持
- 完整日志系统 