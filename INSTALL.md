# UFW Country Blocker - 安装指南

## 🚀 一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/Travisun/UFW-Country-Blocker/main/install.sh | sudo bash
```

## 📋 系统要求

- Ubuntu/Debian系统
- root权限
- 网络连接

## ⚡ 安装过程

一键安装脚本将自动完成以下步骤：

1. ✅ 检查root权限
2. ✅ 检查网络连接
3. ✅ 安装系统依赖（UFW、curl、cron）
4. ✅ 从GitHub下载最新文件
5. ✅ 安装主程序到 `/usr/local/bin/`
6. ✅ 创建日志文件
7. ✅ 启用并配置UFW防火墙
8. ✅ 设置每周星期一早上3点自动更新定时任务
9. ✅ 测试脚本功能
10. ✅ 显示使用说明

## 🔧 安装后配置

安装完成后，编辑配置文件：

```bash
sudo nano /usr/local/bin/ufw_cidr_blocker.conf
```

## 📖 使用方法

```bash
# 手动运行
sudo ufw_cidr_blocker

# 查看日志
sudo tail -f /var/log/ufw_cidr_blocker.log

# 查看UFW状态
sudo ufw status numbered
```

## 🆘 需要帮助？

- 查看完整文档：https://github.com/Travisun/UFW-Country-Blocker
- 提交Issue：https://github.com/Travisun/UFW-Country-Blocker/issues 