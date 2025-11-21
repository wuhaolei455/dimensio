#!/bin/bash

echo "=== Fixing Squid Proxy Conflict ==="
echo ""

echo "1. Checking for Squid process..."
if pgrep -x squid > /dev/null; then
    echo "✗ Squid is running"
    ps aux | grep squid | grep -v grep
else
    echo "✓ Squid is not running"
fi
echo ""

echo "2. Checking Squid service status..."
sudo systemctl status squid --no-pager 2>/dev/null || echo "Squid service not found or not managed by systemd"
echo ""

echo "3. Checking what's listening on port 80..."
sudo netstat -tlnp | grep ':80 '
echo ""

echo "4. Checking nginx status..."
sudo systemctl status nginx --no-pager | head -15
echo ""

echo "5. Stopping and disabling Squid..."
if systemctl is-active --quiet squid; then
    echo "Stopping Squid..."
    sudo systemctl stop squid
    sudo systemctl disable squid
    echo "✓ Squid stopped and disabled"
else
    echo "✓ Squid is not active"
fi
echo ""

echo "6. Verifying port 80 is now free or used by nginx..."
sudo netstat -tlnp | grep ':80 '
echo ""

echo "7. Ensuring nginx is running..."
sudo systemctl enable nginx
sudo systemctl restart nginx
echo ""

echo "8. Final port check..."
sudo netstat -tlnp | grep -E ':(80|3000|5000|8080) '
echo ""

echo "9. Testing local connectivity..."
echo "Testing frontend (nginx -> port 3000)..."
curl -I http://localhost/ 2>&1 | head -10
echo ""

echo "Testing API (nginx -> port 5000)..."
curl -I http://localhost/api/ 2>&1 | head -10
echo ""

echo "Testing backend directly..."
curl -I http://localhost:5000/ 2>&1 | head -10
echo ""

echo "=== Fix Complete ==="
echo ""
echo "Next steps:"
echo "1. If Squid was stopped, try accessing http://8.140.237.35/ again"
echo "2. If still not working, check your cloud provider's security group rules"
echo "   - Aliyun ECS: Allow TCP port 80 in security group"
echo "3. You can also try accessing directly: http://8.140.237.35:8080/"
