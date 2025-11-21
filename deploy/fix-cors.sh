#!/bin/bash

echo "=== Fixing CORS Issue ==="
echo ""

echo "1. Checking backend container..."
docker ps | grep backend
echo ""

echo "2. Stopping backend..."
docker stop dimensio-backend
echo ""

echo "3. Removing backend container..."
docker rm dimensio-backend
echo ""

echo "4. Finding backend image..."
BACKEND_IMAGE=$(docker images | grep -E "(dimensio.*backend|docker_backend|backend)" | head -1 | awk '{print $1":"$2}')
echo "Backend image: $BACKEND_IMAGE"
echo ""

echo "5. Removing old image..."
docker rmi $(echo $BACKEND_IMAGE | cut -d: -f1) 2>/dev/null || echo "Image removed or not found"
echo ""

echo "6. Finding docker-compose.yml or Dockerfile..."
COMPOSE_FILE=$(find /root -name "docker-compose.yml" 2>/dev/null | head -1)
DOCKERFILE=$(find /root -path "*/deploy/docker/Dockerfile.backend" -o -name "Dockerfile.backend" 2>/dev/null | head -1)

if [ -n "$COMPOSE_FILE" ]; then
    echo "✓ Found docker-compose.yml at: $COMPOSE_FILE"
    PROJECT_DIR=$(dirname "$COMPOSE_FILE")
    cd "$PROJECT_DIR"

    echo ""
    echo "7. Rebuilding backend with CORS fix..."
    docker-compose build backend --no-cache
    echo ""

    echo "8. Starting backend..."
    docker-compose up -d backend

elif [ -n "$DOCKERFILE" ]; then
    echo "✓ Found Dockerfile at: $DOCKERFILE"
    DOCKERFILE_DIR=$(dirname "$DOCKERFILE")

    # Find build context
    if [ -d "$DOCKERFILE_DIR/../api" ]; then
        BUILD_CONTEXT="$DOCKERFILE_DIR/.."
    elif [ -d "$DOCKERFILE_DIR/../../api" ]; then
        BUILD_CONTEXT="$DOCKERFILE_DIR/../.."
    else
        BUILD_CONTEXT="/root/dimensio"
    fi

    echo "  Build context: $BUILD_CONTEXT"
    echo ""

    echo "7. Rebuilding backend with CORS fix..."
    docker build -t docker_backend -f "$DOCKERFILE" "$BUILD_CONTEXT" --no-cache
    echo ""

    echo "8. Starting backend..."
    docker run -d \
        --name dimensio-backend \
        -p 5000:5000 \
        -v "$BUILD_CONTEXT/data:/app/data" \
        -v "$BUILD_CONTEXT/result:/app/result" \
        --network docker_default \
        docker_backend
else
    echo "✗ Cannot find docker-compose.yml or Dockerfile"
    echo "  Please manually rebuild the backend container"
    exit 1
fi

echo ""
echo "9. Waiting for backend to start (10 seconds)..."
sleep 10
echo ""

echo "10. Checking backend status..."
docker ps | grep backend
echo ""

echo "11. Checking backend logs..."
docker logs --tail=30 dimensio-backend
echo ""

echo "12. Testing CORS headers..."
echo ""
echo "Test 1: OPTIONS request (preflight)"
curl -X OPTIONS -v http://localhost:5000/api/compression/history \
    -H "Origin: http://8.140.237.35" \
    -H "Access-Control-Request-Method: GET" \
    2>&1 | grep -i "access-control"
echo ""

echo "Test 2: GET request with Origin header"
curl -X GET -v http://localhost:5000/api/compression/history \
    -H "Origin: http://8.140.237.35" \
    2>&1 | grep -i "access-control"
echo ""

echo "=== CORS Fix Complete ==="
echo ""
echo "The following CORS headers should now be present:"
echo "  - Access-Control-Allow-Origin: *"
echo "  - Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS"
echo "  - Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With"
echo ""
echo "Next steps:"
echo "1. Open browser: http://8.140.237.35/"
echo "2. Open Developer Console (F12)"
echo "3. Check Network tab for CORS errors"
echo "4. Try uploading files or viewing history"
echo ""
echo "If CORS errors persist:"
echo "  - Check browser console for specific error messages"
echo "  - Verify Origin header in the request"
echo "  - Run: docker logs -f dimensio-backend"
