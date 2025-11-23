#!/bin/bash

# Free ports used by Dimensio services
# Run this before deployment if ports are occupied

set +e  # Don't exit on error

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "  Port Cleanup for Dimensio"
echo "=========================================="
echo ""

# Function to check and free a port
free_port() {
    local PORT=$1
    local PORT_NAME=$2

    echo -e "${BLUE}Checking port ${PORT} (${PORT_NAME})...${NC}"

    # Try multiple methods to find the process
    local PID=""

    # Method 1: lsof (if available)
    if command -v lsof &> /dev/null; then
        PID=$(lsof -ti:${PORT} 2>/dev/null | head -1)
    fi

    # Method 2: netstat (if lsof not available)
    if [ -z "$PID" ] && command -v netstat &> /dev/null; then
        PID=$(netstat -tlnp 2>/dev/null | grep ":${PORT} " | awk '{print $7}' | cut -d/ -f1 | head -1)
    fi

    # Method 3: ss command
    if [ -z "$PID" ] && command -v ss &> /dev/null; then
        PID=$(ss -tlnp 2>/dev/null | grep ":${PORT} " | grep -oP 'pid=\K[0-9]+' | head -1)
    fi

    if [ -z "$PID" ]; then
        echo -e "  ${GREEN}✓ Port ${PORT} is free${NC}"
        return 0
    fi

    # Get process info
    local PROCESS_NAME=$(ps -p $PID -o comm= 2>/dev/null || echo "unknown")
    local PROCESS_CMD=$(ps -p $PID -o args= 2>/dev/null || echo "")

    echo -e "  ${YELLOW}⚠ Port ${PORT} is occupied${NC}"
    echo "    PID: $PID"
    echo "    Process: $PROCESS_NAME"
    echo "    Command: ${PROCESS_CMD:0:80}"
    echo ""

    # Ask for confirmation before killing
    read -p "  Kill this process? [y/N] " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "  ${YELLOW}⊘ Skipped${NC}"
        return 1
    fi

    # Try graceful stop
    echo "  Attempting graceful stop (SIGTERM)..."
    kill $PID 2>/dev/null
    sleep 2

    # Check if process is still running
    if ps -p $PID > /dev/null 2>&1; then
        echo "  Process still running, trying force kill (SIGKILL)..."
        kill -9 $PID 2>/dev/null
        sleep 1
    fi

    # Verify port is now free
    local CHECK_PID=""
    if command -v lsof &> /dev/null; then
        CHECK_PID=$(lsof -ti:${PORT} 2>/dev/null)
    elif command -v netstat &> /dev/null; then
        CHECK_PID=$(netstat -tlnp 2>/dev/null | grep ":${PORT} " | awk '{print $7}' | cut -d/ -f1 | head -1)
    fi

    if [ -z "$CHECK_PID" ]; then
        echo -e "  ${GREEN}✓ Port ${PORT} freed successfully${NC}"
        return 0
    else
        echo -e "  ${RED}✗ Failed to free port ${PORT}${NC}"
        echo "  Manual action required: sudo kill -9 $PID"
        return 1
    fi
}

# Check for system Nginx
echo -e "${BLUE}Checking for system Nginx service...${NC}"
if systemctl is-active --quiet nginx 2>/dev/null; then
    echo -e "  ${YELLOW}⚠ System Nginx is running${NC}"
    read -p "  Stop system Nginx? [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "  Stopping system Nginx..."
        systemctl stop nginx 2>/dev/null || sudo systemctl stop nginx
        if systemctl is-active --quiet nginx 2>/dev/null; then
            echo -e "  ${RED}✗ Failed to stop system Nginx${NC}"
            echo "  Try: sudo systemctl stop nginx"
        else
            echo -e "  ${GREEN}✓ System Nginx stopped${NC}"
        fi
    fi
else
    echo -e "  ${GREEN}✓ System Nginx is not running${NC}"
fi
echo ""

# Check and free required ports
echo -e "${BLUE}Checking required ports...${NC}"
echo ""

free_port 80 "Nginx/HTTP"
echo ""
free_port 5000 "Backend API"
echo ""
free_port 3000 "Frontend Dev Server"
echo ""

echo "=========================================="
echo "  Port Cleanup Complete"
echo "=========================================="
echo ""

# Show current port status
echo "Current port status:"
echo ""

if command -v lsof &> /dev/null; then
    echo "Port 80:"
    lsof -i:80 2>/dev/null | head -5 || echo "  (free)"
    echo ""
    echo "Port 5000:"
    lsof -i:5000 2>/dev/null | head -5 || echo "  (free)"
    echo ""
    echo "Port 3000:"
    lsof -i:3000 2>/dev/null | head -5 || echo "  (free)"
elif command -v netstat &> /dev/null; then
    netstat -tlnp 2>/dev/null | grep -E ":(80|5000|3000) " || echo "  All ports are free"
else
    echo "  (Unable to check - lsof/netstat not available)"
fi

echo ""
echo "You can now run: ./deploy-docker-only.sh"
echo ""
