#!/bin/bash

# Check for dependencies
if ! command -v wget &>/dev/null; then
    echo "请先安装 wget"
    exit 1
fi

# Fetch the latest release version from GitHub API
latest_version=$(curl -s https://api.github.com/repos/alist-org/alist/releases/latest | grep -oP '"tag_name": "\K(.*?)(?=")')

# Check if the latest version is obtained successfully
if [ -z "$latest_version" ]; then
    echo "无法获取最新版本信息"
    exit 1
fi
https://github.com/alist-org/alist/releases/download/$latest_version/alist-linux-musl-amd64.tar.gz
# Download, install, and clean up
install_dir="/usr/local/bin"
download_url="https://github.com/alist-org/alist/releases/download/$latest_version/alist-linux-musl-amd$(uname -m).tar.gz"

cd "$install_dir" || exit
wget "$download_url" && unzip "alist-linux-musl-amd$(uname -m).tar.gz" && rm "alist-linux-musl-amd$(uname -m).tar.gz"

# Set permissions
chmod +x "${install_dir}/alist"

# Configure systemd service
conf_path="/home"
read -rp "请输入配置文件保存目录(回车默认${conf_path}): " input
[ -n "$input" ] && conf_path="$input"

cat <<EOF > "/etc/systemd/system/alist.service"
[Unit]
Description=alist
After=network.target
 
[Service]
Type=simple
WorkingDirectory=${install_dir}
ExecStart=${install_dir}/qbittorrent-nox/alist server
Restart=on-failure
 
[Install]
WantedBy=multi-user.target
EOF

# 然后，执行 systemctl daemon-reload 重载配置，现在你可以使用这些命令来管理程序：

systemctl daemon-reload
systemctl start alist
systemctl enable alist
systemctl status alist

# Print instructions
echo "--------------------------------"
echo "在浏览器中打开 ip:5244"
echo "======== alist ========"
echo "启动 systemctl start alist"
echo "停止 systemctl stop alist"
echo "状态 systemctl status alist"
echo "开机自启 systemctl enable alist"
echo "禁用自启 systemctl disable alist"
echo "======== qbittorrent-nox ========"
