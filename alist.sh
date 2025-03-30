#!/bin/bash

# Check for dependencies
if ! command -v wget &>/dev/null; then
    echo "请先安装 wget"
    exit 1
fi

# Get platform
if command -v arch >/dev/null 2>&1; then
  platform=$(arch)
else
  platform=$(uname -m)
fi

ARCH="UNKNOWN"

if [ "$platform" = "x86_64" ]; then
  ARCH=amd64
elif [ "$platform" = "aarch64" ]; then
  ARCH=arm64
fi

GH_PROXY='https://mirror.ghproxy.com/'

if [ "$(id -u)" != "0" ]; then
  echo -e "\r\n${RED_COLOR}出错了，请使用 root 权限重试！${RES}\r\n" 1>&2
  exit 1
elif [ "$ARCH" == "UNKNOWN" ]; then
  echo -e "\r\n${RED_COLOR}出错了${RES}，一键安装目前仅支持 x86_64和arm64 平台。\r\n其它平台请参考：${GREEN_COLOR}https://alist.nn.ci${RES}\r\n"
  exit 1
elif ! command -v systemctl >/dev/null 2>&1; then
  echo -e "\r\n${RED_COLOR}出错了${RES}，无法确定你当前的 Linux 发行版。\r\n建议手动安装：${GREEN_COLOR}https://alist.nn.ci${RES}\r\n"
  exit 1
else
  if command -v netstat >/dev/null 2>&1; then
    check_port=$(netstat -lnp | grep 5244 | awk '{print $7}' | awk -F/ '{print $1}')
  else
    echo -e "${GREEN_COLOR}端口检查 ...${RES}"
    if command -v yum >/dev/null 2>&1; then
      yum install net-tools -y >/dev/null 2>&1
      check_port=$(netstat -lnp | grep 5244 | awk '{print $7}' | awk -F/ '{print $1}')
    else
      apt-get update >/dev/null 2>&1
      apt-get install net-tools -y >/dev/null 2>&1
      check_port=$(netstat -lnp | grep 5244 | awk '{print $7}' | awk -F/ '{print $1}')
    fi
  fi
fi

# Fetch the latest release version from GitHub API
latest_version=$(curl -s https://api.github.com/repos/alist-org/alist/releases/latest | grep -oP '"tag_name": "\K(.*?)(?=")')

# Check if the latest version is obtained successfully
if [ -z "$latest_version" ]; then
    echo "无法获取最新版本信息"
    exit 1
fi

# Set installation directory
install_dir="/home/alist"

# Download, install, and clean up
mkdir -p "$install_dir"
download_url="https://github.com/alist-org/alist/releases/download/$latest_version/alist-linux-musl-$ARCH.tar.gz"

wget -O "$install_dir/alist-linux-musl-$ARCH.tar.gz" "$download_url" && tar -xzf "$install_dir/alist-linux-musl-$ARCH.tar.gz" -C "$install_dir" &&rm "$install_dir/alist-linux-musl-$ARCH.tar.gz"

# Set permissions
chmod +x "$install_dir/alist"


cat <<EOF > "/etc/systemd/system/alist.service"
[Unit]
Description=alist
After=network.target
 
[Service]
Type=simple
WorkingDirectory=/home/alist
ExecStart=/home/alist/alist server
Restart=on-failure
 
[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start/enable the service
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
echo "======== alist ========"
