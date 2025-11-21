#!/bin/bash

echo "=== Backend Diagnosis ==="
echo ""

echo "1. Checking backend container status..."
docker ps -a | grep backend
echo ""

echo "2. Checking backend container health..."
docker inspect dimensio-backend | grep -A 10 "Health"
echo ""

echo "3. Checking backend logs (last 200 lines)..."
docker logs --tail=200 dimensio-backend
echo ""

echo "4. Testing backend from host..."
echo "Test 1: Direct connection to port 5000"
curl -v http://localhost:5000/ 2>&1 | head -20
echo ""

echo "Test 2: API endpoint"
curl -v http://localhost:5000/api/ 2>&1 | head -20
echo ""

echo "Test 3: Compression history endpoint"
curl -v http://localhost:5000/api/compression/history 2>&1 | head -20
echo ""

echo "5. Checking if backend is listening inside container..."
docker exec dimensio-backend ps aux
echo ""
docker exec dimensio-backend netstat -tlnp 2>/dev/null || docker exec dimensio-backend ss -tlnp
echo ""

echo "6. Testing backend from inside container..."
docker exec dimensio-backend curl -v http://127.0.0.1:5000/ 2>&1 | head -20
echo ""

echo "7. Checking backend Python process..."
docker exec dimensio-backend ps aux | grep python
echo ""

echo "8. Checking for Python errors..."
docker exec dimensio-backend ls -la /app/api/
echo ""

echo "=== Diagnosis Complete ==="
