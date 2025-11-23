#!/bin/bash

# Diagnose why result directory is empty
# This checks backend service, logs, and data flow

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "  Diagnosing Empty Result Directory"
echo "=========================================="
echo ""

# Check if running in correct directory
if [ ! -d "/root/dimensio" ]; then
    echo -e "${RED}Error: /root/dimensio not found${NC}"
    echo "Are you running on the server?"
    exit 1
fi

echo -e "${BLUE}1. Checking directory structure...${NC}"
echo ""

# Check result directory
if [ -d "/root/dimensio/result" ]; then
    RESULT_COUNT=$(ls -1 /root/dimensio/result 2>/dev/null | wc -l)
    echo "Result directory: /root/dimensio/result"
    echo "  Files/folders: $RESULT_COUNT"

    if [ $RESULT_COUNT -eq 0 ]; then
        echo -e "  ${YELLOW}⚠ Empty (no compression results yet)${NC}"
    else
        echo -e "  ${GREEN}✓ Contains files${NC}"
        ls -lah /root/dimensio/result/ | head -10
    fi
else
    echo -e "${RED}✗ Result directory does not exist${NC}"
fi
echo ""

# Check data directory
if [ -d "/root/dimensio/data" ]; then
    DATA_COUNT=$(ls -1 /root/dimensio/data 2>/dev/null | wc -l)
    echo "Data directory: /root/dimensio/data"
    echo "  Files: $DATA_COUNT"

    if [ $DATA_COUNT -eq 0 ]; then
        echo -e "  ${YELLOW}⚠ Empty (no data uploaded yet)${NC}"
    else
        echo -e "  ${GREEN}✓ Contains files${NC}"
        ls -lah /root/dimensio/data/ | head -10
    fi
else
    echo -e "${RED}✗ Data directory does not exist${NC}"
fi
echo ""

echo -e "${BLUE}2. Checking Docker containers...${NC}"
echo ""

cd /root/dimensio/deploy/docker 2>/dev/null || cd /root/dimensio/docker 2>/dev/null

# Check if containers are running
BACKEND_STATUS=$(docker ps --filter "name=dimensio-backend" --format "{{.Status}}" 2>/dev/null)
if [ -n "$BACKEND_STATUS" ]; then
    echo -e "Backend container: ${GREEN}Running${NC}"
    echo "  Status: $BACKEND_STATUS"
else
    echo -e "Backend container: ${RED}Not running${NC}"
fi
echo ""

echo -e "${BLUE}3. Checking backend logs...${NC}"
echo ""

if docker ps | grep -q "dimensio-backend"; then
    echo "Last 30 lines of backend logs:"
    echo "----------------------------------------"
    docker logs --tail 30 dimensio-backend 2>&1
    echo "----------------------------------------"
    echo ""

    # Check for errors
    ERROR_COUNT=$(docker logs --tail 100 dimensio-backend 2>&1 | grep -i error | wc -l)
    if [ $ERROR_COUNT -gt 0 ]; then
        echo -e "${YELLOW}⚠ Found $ERROR_COUNT error messages in logs${NC}"
        echo ""
        echo "Recent errors:"
        docker logs --tail 100 dimensio-backend 2>&1 | grep -i error | tail -5
    else
        echo -e "${GREEN}✓ No error messages in recent logs${NC}"
    fi
else
    echo -e "${RED}✗ Backend container not running${NC}"
fi
echo ""

echo -e "${BLUE}4. Checking volume mounts...${NC}"
echo ""

if docker ps | grep -q "dimensio-backend"; then
    echo "Checking if volumes are correctly mounted:"
    docker inspect dimensio-backend --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}' | grep -E "data|result"

    # Check if directories exist inside container
    echo ""
    echo "Directories inside backend container:"
    docker exec dimensio-backend ls -lah /app/ | grep -E "data|result|run_compression"
else
    echo -e "${RED}✗ Cannot check - backend not running${NC}"
fi
echo ""

echo -e "${BLUE}5. Testing backend API...${NC}"
echo ""

# Test if backend is responding
echo -n "Testing backend API endpoint... "
BACKEND_TEST=$(curl -s -m 5 http://localhost:5000/ 2>/dev/null)
if echo "$BACKEND_TEST" | grep -q "Dimensio"; then
    echo -e "${GREEN}✓ Backend responding${NC}"
    echo ""
    echo "API info:"
    echo "$BACKEND_TEST" | python3 -m json.tool 2>/dev/null | head -20
else
    echo -e "${RED}✗ Backend not responding${NC}"
fi
echo ""

# Test compression history endpoint
echo -n "Testing compression history endpoint... "
HISTORY_TEST=$(curl -s -m 5 http://localhost:5000/api/compression/history 2>/dev/null)
if echo "$HISTORY_TEST" | grep -q "success"; then
    if echo "$HISTORY_TEST" | grep -q '"success": false'; then
        echo -e "${YELLOW}⚠ No compression history found${NC}"
        echo "  Reason: No compression has been executed yet"
    else
        echo -e "${GREEN}✓ History found${NC}"
        echo "$HISTORY_TEST" | python3 -m json.tool 2>/dev/null | head -20
    fi
else
    echo -e "${RED}✗ API error or not responding${NC}"
fi
echo ""

echo -e "${BLUE}6. Checking file permissions...${NC}"
echo ""

echo "Result directory permissions:"
ls -lhd /root/dimensio/result/
echo ""

echo "Data directory permissions:"
ls -lhd /root/dimensio/data/
echo ""

# Check if Docker user can write
if [ -d "/root/dimensio/result" ]; then
    TEST_FILE="/root/dimensio/result/.write_test"
    if touch "$TEST_FILE" 2>/dev/null; then
        echo -e "${GREEN}✓ Result directory is writable${NC}"
        rm -f "$TEST_FILE"
    else
        echo -e "${RED}✗ Result directory is not writable${NC}"
        echo "  This could cause compression to fail"
    fi
fi
echo ""

echo "=========================================="
echo "  Diagnosis Summary"
echo "=========================================="
echo ""

# Summary
echo -e "${BLUE}Possible reasons for empty result directory:${NC}"
echo ""

if [ $DATA_COUNT -eq 0 ]; then
    echo -e "${YELLOW}1. No files have been uploaded yet${NC}"
    echo "   → Upload files via the web interface"
    echo "   → Or manually place files in /root/dimensio/data/"
    echo ""
fi

if [ -z "$BACKEND_STATUS" ]; then
    echo -e "${RED}2. Backend is not running${NC}"
    echo "   → Start backend: cd /root/dimensio/deploy/docker && docker-compose up -d"
    echo ""
fi

if [ $ERROR_COUNT -gt 0 ]; then
    echo -e "${YELLOW}3. Backend has errors${NC}"
    echo "   → Check logs: docker logs dimensio-backend"
    echo "   → Look for error messages"
    echo ""
fi

echo -e "${BLUE}How compression works:${NC}"
echo "  1. User uploads files via web interface (http://8.140.237.35/)"
echo "  2. Files are saved to /root/dimensio/data/"
echo "  3. Backend validates and processes files"
echo "  4. Compression script runs"
echo "  5. Results are saved to /root/dimensio/result/"
echo ""

echo -e "${BLUE}Next steps:${NC}"
echo ""

if [ $DATA_COUNT -eq 0 ]; then
    echo "1. Upload test files:"
    echo "   - Go to http://8.140.237.35/"
    echo "   - Click 'Configure & Upload'"
    echo "   - Upload config_space.json, steps.json, history.json"
    echo ""
fi

if [ -n "$BACKEND_STATUS" ]; then
    echo "2. Monitor backend logs while uploading:"
    echo "   docker logs -f dimensio-backend"
    echo ""
fi

echo "3. Check for detailed errors:"
echo "   ./check-backend-errors.sh"
echo ""

echo "4. Manual test upload:"
echo "   curl -X POST http://localhost:5000/api/upload \\"
echo "     -F 'config_space=@/path/to/config_space.json' \\"
echo "     -F 'steps=@/path/to/steps.json' \\"
echo "     -F 'history=@/path/to/history.json'"
echo ""

# Create a quick test
echo -e "${BLUE}Quick test available:${NC}"
echo "  Run: ./test-backend-upload.sh"
echo "  This will create and upload test files"
echo ""
