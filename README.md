# UFW CIDR Blocker

一个基于UFW防火墙的CIDR列表自动阻止工具，支持IPv4和IPv6 CIDR列表，可以自动下载并应用国家/地区的IP地址段到防火墙规则中。

## 功能特性

- 🔥 **自动下载CIDR列表**：支持从GitHub等源自动下载最新的CIDR列表
- 🌍 **多国家支持**：默认支持中国IP列表，可轻松扩展到其他国家
- 🔒 **UFW集成**：完全集成到UFW防火墙系统中
- 📊 **IPv4/IPv6支持**：同时支持IPv4和IPv6地址段
- ⚡ **高性能**：优化的脚本性能，支持大量CIDR规则
- 🔄 **自动更新**：支持systemd定时器自动更新规则
- 📝 **详细日志**：完整的操作日志记录
- 🛡️ **安全可靠**：包含错误处理和回滚机制

## 系统要求

- Linux系统（推荐Ubuntu/Debian）
- UFW防火墙
- curl工具
- root权限

## 快速安装

### 方法一：GitHub一键安装（推荐）

```bash
# 从GitHub直接安装
curl -fsSL https://raw.githubusercontent.com/Travisun/UFW-Country-Blocker/main/install_github.sh | sudo bash
```

### 方法二：本地安装

```bash
# 下载项目
git clone https://github.com/Travisun/UFW-Country-Blocker.git
cd UFW-Country-Blocker

# 运行安装脚本
sudo bash install.sh
```

### 方法二：手动安装

```bash
# 1. 复制主脚本
sudo cp ufw_cidr_blocker.sh /usr/local/bin/ufw_cidr_blocker
sudo chmod +x /usr/local/bin/ufw_cidr_blocker

# 2. 复制配置文件
sudo cp ufw_cidr_blocker.conf /usr/local/bin/ufw_cidr_blocker.conf

# 3. 创建日志文件
sudo touch /var/log/ufw_cidr_blocker.log
sudo chmod 644 /var/log/ufw_cidr_blocker.log

# 4. 安装systemd服务（可选）
sudo cp ufw_cidr_blocker.service /etc/systemd/system/
sudo cp ufw_cidr_blocker.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable ufw_cidr_blocker.timer
sudo systemctl start ufw_cidr_blocker.timer
```

## 使用方法

### 手动运行

```bash
# 手动执行一次
sudo /usr/local/bin/ufw_cidr_blocker
```

### 查看状态

```bash
# 查看定时器状态
sudo systemctl status ufw_cidr_blocker.timer

# 查看服务日志
sudo journalctl -u ufw_cidr_blocker.service

# 查看脚本日志
sudo tail -f /var/log/ufw_cidr_blocker.log
```

### 管理定时器

```bash
# 停止定时器
sudo systemctl stop ufw_cidr_blocker.timer

# 禁用定时器
sudo systemctl disable ufw_cidr_blocker.timer

# 重新启用定时器
sudo systemctl enable ufw_cidr_blocker.timer
sudo systemctl start ufw_cidr_blocker.timer
```

## 配置说明

编辑配置文件 `/usr/local/bin/ufw_cidr_blocker.conf`：

```bash
sudo nano /usr/local/bin/ufw_cidr_blocker.conf
```

### 主要配置项

```bash
# CIDR列表URL配置
IPV4_URLS=("https://raw.githubusercontent.com/Travisun/Latest-Country-IP-List/refs/heads/main/data/cidr_lists/cn_ipv4.txt")
IPV6_URLS=("https://raw.githubusercontent.com/Travisun/Latest-Country-IP-List/refs/heads/main/data/cidr_lists/cn_ipv6.txt")

# 防火墙规则配置
BLOCK_PORTS=("53")           # 要阻止的端口
BLOCK_PROTOCOLS=("tcp" "udp") # 要阻止的协议
BLOCK_ICMP=true              # 是否阻止ICMP
BLOCK_IPV6_ICMP=true         # 是否阻止IPv6 ICMP

# 测试模式配置
TEST_MODE=false              # 测试模式开关
TEST_CIDR_LIMIT=10           # 测试模式下的CIDR数量限制
```

### 添加其他国家

要阻止其他国家的IP，只需修改URL配置：

```bash
# 例如：阻止美国IP
IPV4_URLS=("https://raw.githubusercontent.com/Travisun/Latest-Country-IP-List/refs/heads/main/data/cidr_lists/us_ipv4.txt")
IPV6_URLS=("https://raw.githubusercontent.com/Travisun/Latest-Country-IP-List/refs/heads/main/data/cidr_lists/us_ipv6.txt")

# 阻止多个国家
IPV4_URLS=(
    "https://raw.githubusercontent.com/Travisun/Latest-Country-IP-List/refs/heads/main/data/cidr_lists/cn_ipv4.txt"
    "https://raw.githubusercontent.com/Travisun/Latest-Country-IP-List/refs/heads/main/data/cidr_lists/ru_ipv4.txt"
)
```

## 卸载

### 使用卸载脚本（推荐）

```bash
# GitHub卸载
curl -fsSL https://raw.githubusercontent.com/Travisun/UFW-Country-Blocker/main/uninstall_github.sh | sudo bash

# 或本地卸载
sudo bash uninstall.sh
```

### 手动卸载

```bash
# 1. 停止并禁用服务
sudo systemctl stop ufw_cidr_blocker.timer
sudo systemctl disable ufw_cidr_blocker.timer

# 2. 删除UFW规则
sudo ufw status numbered | grep "AUTO_BLOCK_CIDR" | awk -F'[][]' '{print $2}' | sort -nr | xargs -I {} echo "y" | sudo ufw delete {}

# 3. 删除文件
sudo rm -f /usr/local/bin/ufw_cidr_blocker
sudo rm -f /usr/local/bin/ufw_cidr_blocker.conf
sudo rm -f /var/log/ufw_cidr_blocker.log
sudo rm -f /var/run/ufw_cidr_blocker.lock
sudo rm -rf /tmp/ufw_cidr_blocker
sudo rm -f /etc/systemd/system/ufw_cidr_blocker.service
sudo rm -f /etc/systemd/system/ufw_cidr_blocker.timer

# 4. 重新加载systemd
sudo systemctl daemon-reload
```

## 故障排除

### 常见问题

1. **脚本无法创建规则**
   - 检查UFW是否启用：`sudo ufw status`
   - 检查权限：确保以root权限运行
   - 查看详细日志：`sudo tail -f /var/log/ufw_cidr_blocker.log`

2. **下载CIDR列表失败**
   - 检查网络连接
   - 验证URL是否可访问
   - 检查curl是否安装

3. **systemd服务无法启动**
   - 检查服务文件语法：`sudo systemctl status ufw_cidr_blocker.service`
   - 查看服务日志：`sudo journalctl -u ufw_cidr_blocker.service`

### 调试模式

启用测试模式进行调试：

```bash
# 编辑配置文件
sudo nano /usr/local/bin/ufw_cidr_blocker.conf

# 启用测试模式
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

## 安全注意事项

1. **备份现有规则**：安装前建议备份现有UFW规则
   ```bash
   sudo ufw status numbered > ufw_backup_$(date +%Y%m%d).txt
   ```

2. **测试网络连接**：首次运行后测试网络连接是否正常

3. **监控日志**：定期检查日志文件确保脚本正常运行

4. **定期更新**：保持CIDR列表和脚本的更新

## 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 贡献

欢迎提交 Issue 和 Pull Request！

## 更新日志

### v1.0.0
- 初始版本发布
- 支持IPv4/IPv6 CIDR列表
- 集成UFW防火墙
- 支持systemd定时器
- 完整的安装/卸载脚本

## 支持

如果遇到问题，请：

1. 查看本文档的故障排除部分
2. 检查日志文件
3. 提交 Issue 到 GitHub

---

**注意**：使用本工具前请确保了解其影响，建议在测试环境中先进行验证。 