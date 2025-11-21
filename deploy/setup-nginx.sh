#!/bin/bash

echo "=== Setting up System Nginx Reverse Proxy ==="
echo ""

# 检查 nginx 是否安装
if ! command -v nginx &> /dev/null; then
    echo "Nginx is not installed. Installing..."
    sudo apt update
    sudo apt install -y nginx
fi

# 备份原配置
if [ -f /etc/nginx/sites-enabled/default ]; then
    echo "Backing up default nginx config..."
    sudo cp /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.bak.$(date +%Y%m%d_%H%M%S)
fi

# 复制新配置
echo "Installing new nginx configuration..."
sudo cp nginx-system.conf /etc/nginx/sites-available/dimensio
sudo ln -sf /etc/nginx/sites-available/dimensio /etc/nginx/sites-enabled/dimensio

# 删除默认配置（可选）
if [ -f /etc/nginx/sites-enabled/default ]; then
    echo "Removing default config..."
    sudo rm /etc/nginx/sites-enabled/default
fi

# 测试配置
echo "Testing nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "Configuration test passed. Reloading nginx..."
    sudo systemctl reload nginx
    echo ""
    echo "✓ Nginx configuration updated successfully!"
    echo ""
    echo "You can now access:"
    echo "  - Frontend: http://8.140.237.35/"
    echo "  - API: http://8.140.237.35/api/"
    echo ""
else
    echo "✗ Configuration test failed. Please check the error messages above."
    exit 1
fi
