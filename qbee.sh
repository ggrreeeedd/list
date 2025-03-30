#!/bin/bash

# Check for dependencies
if ! command -v wget &>/dev/null; then
    echo "请先安装 wget"
    exit 1
fi

# Fetch the latest release version from GitHub API
latest_version=$(curl -s https://api.github.com/repos/c0re100/qBittorrent-Enhanced-Edition/releases/latest | grep -oP '"tag_name": "\K(.*?)(?=")')

# Check if the latest version is obtained successfully
if [ -z "$latest_version" ]; then
    echo "无法获取最新版本信息"
    exit 1
fi

# Download, install, and clean up
install_dir="/usr/local/bin"
download_url="https://github.com/c0re100/qBittorrent-Enhanced-Edition/releases/download/$latest_version/qbittorrent-enhanced-nox_$(uname -m)-linux-musl_static.zip"

cd "$install_dir" || exit
wget "$download_url" && unzip "qbittorrent-enhanced-nox_$(uname -m)-linux-musl_static.zip" && rm "qbittorrent-enhanced-nox_$(uname -m)-linux-musl_static.zip"

# Set permissions
chmod +x "${install_dir}/qbittorrent-nox"

# Configure systemd service
conf_path="/home"
read -rp "请输入配置文件保存目录(回车默认${conf_path}): " input
[ -n "$input" ] && conf_path="$input"

cat <<EOF > "/etc/systemd/system/qbittorrent-nox.service"
[Unit]
Description=qBittorrent Service
After=network.target nss-lookup.target

[Service]
UMask=000
ExecStart=${install_dir}/qbittorrent-nox --profile="${conf_path}" --webui-port=18080
WorkingDirectory=${install_dir}
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, start, enable, and show service status
systemctl daemon-reload
systemctl start qbittorrent-nox
systemctl enable qbittorrent-nox
systemctl status qbittorrent-nox

# Print instructions
echo "--------------------------------"
echo "在浏览器中打开 ip:18080"
echo "用户: admin"
echo "密码: adminadmin"
echo "停止后再编辑配置文件 ${conf_path}/qBittorrent/config/qBittorrent.conf"
echo "--------------------------------"
echo "======== qbittorrent-nox ========"
echo "启动 systemctl start qbittorrent-nox"
echo "停止 systemctl stop qbittorrent-nox"
echo "状态 systemctl status qbittorrent-nox"
echo "开机自启 systemctl enable qbittorrent-nox"
echo "禁用自启 systemctl disable qbittorrent-nox"
echo "======== qbittorrent-nox ========"

