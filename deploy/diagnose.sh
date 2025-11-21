#!/bin/bash

echo "=== Docker Diagnosis Script ==="
echo ""

echo "1. Checking Docker status..."
sudo systemctl status docker --no-pager | head -20
echo ""

echo "2. Checking Docker containers..."
docker ps -a
echo ""

echo "3. Checking docker-compose services..."
cd /path/to/dimensio  # Update this path
docker-compose ps
echo ""

echo "4. Checking port bindings..."
docker-compose ps --services | xargs -I {} docker-compose port {}
echo ""

echo "5. Checking backend logs (last 50 lines)..."
docker-compose logs --tail=50 backend
echo ""

echo "6. Checking frontend logs (last 50 lines)..."
docker-compose logs --tail=50 frontend
echo ""

echo "7. Checking nginx logs (last 50 lines)..."
docker-compose logs --tail=50 nginx
echo ""

echo "8. Checking listening ports..."
sudo netstat -tlnp | grep -E ':(80|5000|3000)'
echo ""

echo "9. Checking firewall status..."
sudo ufw status
echo ""

echo "10. Testing local connectivity..."
curl -v http://localhost/api/ 2>&1 | head -20
echo ""

echo "11. Testing backend directly..."
curl -v http://localhost:5000/ 2>&1 | head -20
echo ""

echo "=== Diagnosis Complete ==="
