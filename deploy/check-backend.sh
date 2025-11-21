#!/bin/bash

echo "=== Checking Backend Service ==="
echo ""

echo "1. Checking backend container status..."
docker ps | grep backend
echo ""

echo "2. Checking backend logs (last 100 lines)..."
docker logs --tail=100 dimensio-backend
echo ""

echo "3. Testing backend health..."
curl -v http://localhost:5000/api/ 2>&1
echo ""

echo "4. Checking if backend is actually listening..."
docker exec dimensio-backend netstat -tlnp 2>/dev/null || docker exec dimensio-backend ss -tlnp
echo ""

echo "5. Testing from within backend container..."
docker exec dimensio-backend curl -v http://localhost:5000/api/ 2>&1
echo ""

echo "=== Backend Check Complete ==="
