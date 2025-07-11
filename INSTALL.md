# UFW CIDR Blocker 安装说明

## 快速安装

### 方法一：GitHub一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/Travisun/UFW-Country-Blocker/main/install_github.sh | sudo bash
```

### 方法二：本地安装

```bash
# 下载项目
git clone https://github.com/Travisun/UFW-Country-Blocker.git
cd UFW-Country-Blocker

# 安装
sudo bash install.sh
```

## 系统要求

- Linux系统（推荐Ubuntu/Debian）
- UFW防火墙
- curl工具
- root权限

## 安装后配置

1. 编辑配置文件：
```bash
sudo nano /usr/local/bin/ufw_cidr_blocker.conf
```

2. 手动运行一次：
```bash
sudo /usr/local/bin/ufw_cidr_blocker
```

3. 查看状态：
```bash
sudo systemctl status ufw_cidr_blocker.timer
```

## 卸载

```bash
# GitHub卸载
curl -fsSL https://raw.githubusercontent.com/Travisun/UFW-Country-Blocker/main/uninstall_github.sh | sudo bash

# 或本地卸载
sudo bash uninstall.sh
```

## 默认配置

- 阻止目标：中国IP
- 阻止端口：53 (DNS)
- 阻止协议：TCP, UDP
- 自动更新：每天凌晨2点 