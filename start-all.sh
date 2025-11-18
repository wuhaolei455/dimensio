#!/bin/bash

# Dimensio Full Stack Startup Script
# This script starts both the API server and the frontend dev server

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONT_DIR="$PROJECT_ROOT/front"
LOG_DIR="$PROJECT_ROOT/logs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "========================================"
echo "  Dimensio Visualization Stack Startup"
echo "========================================"
echo ""

# Create logs directory
mkdir -p "$LOG_DIR"

# Function to cleanup on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}Shutting down services...${NC}"

    # Kill background processes
    if [ ! -z "$API_PID" ]; then
        echo "Stopping API server (PID: $API_PID)..."
        kill $API_PID 2>/dev/null || true
    fi

    if [ ! -z "$FRONT_PID" ]; then
        echo "Stopping frontend (PID: $FRONT_PID)..."
        kill $FRONT_PID 2>/dev/null || true
        # Also kill webpack-dev-server
        pkill -f "webpack serve" 2>/dev/null || true
    fi

    echo -e "${GREEN}Services stopped.${NC}"
    exit 0
}

# Register cleanup function
trap cleanup INT TERM EXIT

# Check if Python is available
echo -e "${BLUE}[1/5] Checking Python...${NC}"
if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
    echo -e "${RED}Error: Python is not installed${NC}"
    exit 1
fi

PYTHON_CMD=$(command -v python3 || command -v python)
echo -e "${GREEN}✓ Python found: $PYTHON_CMD${NC}"

# Check if Node.js is available
echo ""
echo -e "${BLUE}[2/5] Checking Node.js...${NC}"
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Node.js found: $(node --version)${NC}"

# Check if frontend dependencies are installed
echo ""
echo -e "${BLUE}[3/5] Checking frontend dependencies...${NC}"
if [ ! -d "$FRONT_DIR/node_modules" ]; then
    echo -e "${YELLOW}Frontend dependencies not found. Installing...${NC}"
    cd "$FRONT_DIR"
    npm install
    cd "$PROJECT_ROOT"
fi
echo -e "${GREEN}✓ Frontend dependencies ready${NC}"

# Start API server
echo ""
echo -e "${BLUE}[4/5] Starting API server...${NC}"
cd "$PROJECT_ROOT"
$PYTHON_CMD -m api.server > "$LOG_DIR/api.log" 2>&1 &
API_PID=$!

# Wait a moment for API to start
sleep 2

# Check if API is running
if ! kill -0 $API_PID 2>/dev/null; then
    echo -e "${RED}Error: API server failed to start${NC}"
    echo "Check logs at: $LOG_DIR/api.log"
    cat "$LOG_DIR/api.log"
    exit 1
fi

echo -e "${GREEN}✓ API server started (PID: $API_PID)${NC}"
echo "  Log file: $LOG_DIR/api.log"
echo "  API URL: http://127.0.0.1:5000"

# Wait for API to be responsive
echo ""
echo -e "${BLUE}Waiting for API to be ready...${NC}"
for i in {1..10}; do
    if curl -s http://127.0.0.1:5000/ > /dev/null 2>&1; then
        echo -e "${GREEN}✓ API is responsive${NC}"
        break
    fi
    if [ $i -eq 10 ]; then
        echo -e "${RED}Error: API server not responding${NC}"
        exit 1
    fi
    sleep 1
done

# Start frontend
echo ""
echo -e "${BLUE}[5/5] Starting frontend...${NC}"
cd "$FRONT_DIR"
npm run dev > "$LOG_DIR/frontend.log" 2>&1 &
FRONT_PID=$!

# Wait a moment for frontend to start
sleep 3

if ! kill -0 $FRONT_PID 2>/dev/null; then
    echo -e "${RED}Error: Frontend failed to start${NC}"
    echo "Check logs at: $LOG_DIR/frontend.log"
    cat "$LOG_DIR/frontend.log"
    exit 1
fi

echo -e "${GREEN}✓ Frontend started (PID: $FRONT_PID)${NC}"
echo "  Log file: $LOG_DIR/frontend.log"
echo "  Frontend URL: http://localhost:3000"

echo ""
echo "========================================"
echo -e "${GREEN}✓ All services started successfully!${NC}"
echo "========================================"
echo ""
echo "Services:"
echo "  → API Server:  http://127.0.0.1:5000"
echo "  → Frontend:    http://localhost:3000"
echo ""
echo "Log files:"
echo "  → API:       $LOG_DIR/api.log"
echo "  → Frontend:  $LOG_DIR/frontend.log"
echo ""
echo "Commands:"
echo "  → View API logs:      tail -f $LOG_DIR/api.log"
echo "  → View frontend logs: tail -f $LOG_DIR/frontend.log"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}"
echo ""

# Wait for user interrupt
wait
