#!/bin/bash

echo "=== Finding Dimensio Project Files ==="
echo ""

echo "1. Looking for docker-compose.yml..."
find / -name "docker-compose.yml" -type f 2>/dev/null | grep -v "/proc" | head -10
echo ""

echo "2. Looking for Dockerfile.backend..."
find / -name "Dockerfile.backend" -type f 2>/dev/null | grep -v "/proc" | head -10
echo ""

echo "3. Looking for api/server.py..."
find / -name "server.py" -path "*/api/*" -type f 2>/dev/null | grep -v "/proc" | head -10
echo ""

echo "4. Checking running Docker containers..."
docker ps -a
echo ""

echo "5. Checking Docker images..."
docker images | grep -E "(dimensio|backend|frontend|nginx)"
echo ""

echo "6. Checking Docker networks..."
docker network ls
echo ""

echo "7. Inspecting backend container (if exists)..."
docker inspect dimensio-backend 2>/dev/null | grep -A 20 "Mounts\|NetworkSettings\|Cmd"
echo ""

echo "8. Checking /root directory structure..."
ls -la /root/ | head -20
echo ""

echo "9. Checking if there's a dimensio directory..."
if [ -d "/root/dimensio" ]; then
    echo "✓ Found /root/dimensio"
    ls -la /root/dimensio/
else
    echo "✗ /root/dimensio not found"
fi
echo ""

echo "10. Looking in common locations..."
for dir in /root/dimensio /home/*/dimensio /opt/dimensio; do
    if [ -d "$dir" ]; then
        echo "✓ Found $dir"
        echo "  Contents:"
        ls -la "$dir" | head -10
        echo ""
    fi
done

echo "=== Search Complete ==="
