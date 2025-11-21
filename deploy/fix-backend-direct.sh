#!/bin/bash

echo "=== Fixing Backend 502 Error (Direct Docker Method) ==="
echo ""

echo "1. Finding docker-compose.yml location..."
COMPOSE_FILE=$(find / -name "docker-compose.yml" -type f 2>/dev/null | grep -E "(dimensio|deploy)" | head -1)

if [ -z "$COMPOSE_FILE" ]; then
    echo "⚠️  docker-compose.yml not found, using direct docker commands"
    USE_DOCKER_DIRECT=true
else
    echo "✓ Found docker-compose.yml at: $COMPOSE_FILE"
    PROJECT_DIR=$(dirname "$COMPOSE_FILE")
    cd "$PROJECT_DIR"
    echo "  Working directory: $PROJECT_DIR"
    USE_DOCKER_DIRECT=false
fi
echo ""

echo "2. Checking current backend container..."
docker ps -a | grep backend
echo ""

echo "3. Stopping backend container..."
if [ "$USE_DOCKER_DIRECT" = true ]; then
    docker stop dimensio-backend 2>/dev/null || echo "Container not running or already stopped"
else
    docker-compose stop backend
fi
echo ""

echo "4. Removing old backend container..."
if [ "$USE_DOCKER_DIRECT" = true ]; then
    docker rm dimensio-backend 2>/dev/null || echo "Container already removed"
else
    docker-compose rm -f backend
fi
echo ""

echo "5. Finding backend image..."
BACKEND_IMAGE=$(docker images | grep -E "(dimensio.*backend|backend.*dimensio|docker_backend)" | head -1 | awk '{print $1":"$2}')
if [ -z "$BACKEND_IMAGE" ]; then
    echo "⚠️  Backend image not found, will need to rebuild"
    BACKEND_IMAGE="docker_backend"
fi
echo "  Backend image: $BACKEND_IMAGE"
echo ""

echo "6. Removing old backend image..."
docker rmi $BACKEND_IMAGE 2>/dev/null || echo "Image already removed or in use"
echo ""

echo "7. Finding Dockerfile location..."
BACKEND_DOCKERFILE=$(find / -path "*/deploy/docker/Dockerfile.backend" -o -path "*/Dockerfile.backend" 2>/dev/null | head -1)
if [ -z "$BACKEND_DOCKERFILE" ]; then
    echo "⚠️  Dockerfile.backend not found, trying alternative locations..."
    BACKEND_DOCKERFILE=$(find /root -name "Dockerfile*" | grep -i backend | head -1)
fi

if [ -n "$BACKEND_DOCKERFILE" ]; then
    echo "✓ Found Dockerfile at: $BACKEND_DOCKERFILE"
    DOCKERFILE_DIR=$(dirname "$BACKEND_DOCKERFILE")

    # Find the project root (should contain api/ directory)
    if [ -d "$DOCKERFILE_DIR/../api" ]; then
        BUILD_CONTEXT="$DOCKERFILE_DIR/.."
    elif [ -d "$DOCKERFILE_DIR/../../api" ]; then
        BUILD_CONTEXT="$DOCKERFILE_DIR/../.."
    else
        BUILD_CONTEXT="/root/dimensio"
    fi

    echo "  Build context: $BUILD_CONTEXT"
    echo ""

    echo "8. Rebuilding backend image..."
    docker build -t docker_backend -f "$BACKEND_DOCKERFILE" "$BUILD_CONTEXT" --no-cache
    echo ""
else
    echo "✗ Cannot find Dockerfile, will try using docker-compose"
    if [ "$USE_DOCKER_DIRECT" = false ]; then
        docker-compose build backend --no-cache
    else
        echo "✗ Cannot rebuild without Dockerfile or docker-compose.yml"
        exit 1
    fi
fi

echo "9. Starting backend container..."
if [ "$USE_DOCKER_DIRECT" = true ]; then
    # Start container directly
    docker run -d \
        --name dimensio-backend \
        --network docker_default \
        -p 5000:5000 \
        -v /root/dimensio/data:/app/data \
        -v /root/dimensio/result:/app/result \
        docker_backend
else
    docker-compose up -d backend
fi
echo ""

echo "10. Waiting for backend to start (15 seconds)..."
sleep 15
echo ""

echo "11. Checking backend status..."
docker ps | grep backend
echo ""

echo "12. Checking backend logs..."
docker logs --tail=50 dimensio-backend
echo ""

echo "13. Testing backend connectivity..."
echo ""
echo "Test 1: Backend root endpoint"
curl -s -w "\nHTTP Status: %{http_code}\n" http://localhost:5000/ | head -30
echo ""

echo "Test 2: API compression history"
curl -s -w "\nHTTP Status: %{http_code}\n" http://localhost:5000/api/compression/history | head -30
echo ""

echo "Test 3: Through nginx proxy"
curl -s -w "\nHTTP Status: %{http_code}\n" http://localhost/api/compression/history | head -30
echo ""

echo "14. Checking if backend is listening on 0.0.0.0:5000..."
docker exec dimensio-backend netstat -tlnp 2>/dev/null | grep 5000 || docker exec dimensio-backend ss -tlnp 2>/dev/null | grep 5000 || echo "Cannot check (netstat/ss not available in container)"
echo ""

echo "15. Checking backend process..."
docker exec dimensio-backend ps aux | grep python
echo ""

echo "=== Backend Fix Complete ==="
echo ""
echo "Next steps:"
echo "1. Open browser: http://8.140.237.35/"
echo "2. Check if the 502 error is gone"
echo "3. Open browser console (F12) to check for errors"
echo ""
echo "If still having issues:"
echo "  - Check logs: docker logs -f dimensio-backend"
echo "  - Check nginx config: cat /etc/nginx/sites-enabled/dimensio"
echo "  - Test directly: curl -v http://localhost:5000/api/compression/history"
